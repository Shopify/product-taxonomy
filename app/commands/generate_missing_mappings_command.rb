# frozen_string_literal: true

class GenerateMissingMappingsCommand < ApplicationCommand
  MAX_RETRIES = 3
  QDRANT_PORT = 6333
  EMBEDDING_MODEL = "text-embedding-3-small"
  MAPPING_GRADER_GPT_MODEL = "gpt-4"

  usage do
    no_command
  end

  def execute
    frame("Generating missing mappings") do
      find_unmapped_categories
      return if @unmapped_category_groups.empty?

      generate_missing_mappings_for_groups
    end
  end

  private

  def find_unmapped_categories
    spinner("Searching Shopify categories that lack mappings") do
      @unmapped_category_groups = []
      all_shopify_category_ids = Set.new(Category.all.pluck(:id))
      latest_shopify_version = "shopify/#{sys.read_file("VERSION").strip}"
      MappingRule.where(
        input_version: latest_shopify_version,
      ).group_by(&:output_version).each do |output_version, mappings|
        shopify_category_ids_from_mappings_input = Set.new(
          mappings.map do |mapping|
            mapping.input.product_category_id.split("/").last
          end,
        )
        unmapped_category_ids = all_shopify_category_ids - shopify_category_ids_from_mappings_input
        category_ids_full_names = unmapped_category_ids.sort.map do |id|
          category_full_name = Category.find(id)&.full_name
          [id, category_full_name] if category_full_name
        end.compact.to_h
        next if category_ids_full_names.empty?

        @unmapped_category_groups << {
          input_taxonomy: mappings.first.input_version,
          output_taxonomy: output_version,
          category_ids_full_names: category_ids_full_names,
        }
      end
    end
  end

  def load_embedding_data(output_taxonomy)
    embeddings = nil
    spinner("Loading embeddings for #{output_taxonomy}") do
      files = sys.glob("data/integrations/#{output_taxonomy}/embeddings/_*.txt")
      embeddings = files.each_with_object({}) do |partition, embedding_data|
        sys.read_file(partition).each_line do |line|
          word, vector_str = line.chomp.split(":", 2)
          vector = vector_str.split(", ").map { |num| BigDecimal(num).to_f }
          embedding_data[word] = vector
        end
      end
    end
    embeddings
  end

  def index_embedding_data(embedding_data:, index_name:)
    spinner("Indexing embeddings for #{index_name}") do
      qdrant_client.collections.delete(collection_name: index_name)
      qdrant_client.collections.create(
        collection_name: index_name,
        vectors: { size: 1536, distance: "Cosine" },
      )

      points = embedding_data.map.with_index do |(key, value), index|
        {
          id: index + 1,
          vector: value,
          payload: { index_name => key },
        }
      end

      points.each_slice(100) do |batch|
        qdrant_client.points.upsert(
          collection_name: index_name,
          points: batch,
        )
      end
    end
  end

  def generate_and_evaluate_mappings_for_group(
    unmapped_category_group:,
    index_name:
  )
    spinner("Generating and evaluating mappings for each Shopify category") do
      destination_taxonomy_ids_by_full_name = load_destination_taxonomy_ids(unmapped_category_group[:output_taxonomy])
      mapping_file_path = "data/integrations/#{unmapped_category_group[:output_taxonomy]}/mappings/from_shopify.yml"
      mapping_data = YAML.load_file(mapping_file_path)

      disagree_messages = []
      unmapped_category_group[:category_ids_full_names].each do |source_category_id, source_category_name|
        generated_mapping = generate_mapping(
          source_category_id:,
          source_category_name:,
          index_name:,
          destination_taxonomy_ids_by_full_name:,
        )
        mapping_data["rules"] << generated_mapping[:new_entry]
        disagree_messages << generated_mapping[:mapping_to_be_graded] if generated_mapping[:grading_result] == "No"
      end

      mapping_data["rules"].sort_by! { |rule| rule["input"]["product_category_id"] }
      sys.write_file(mapping_file_path) do |file|
        file.write(mapping_data.to_yaml)
      end

      write_disagree_messages(disagree_messages) if disagree_messages.any?
    end
  end

  def load_destination_taxonomy_ids(output_taxonomy)
    logger.debug("Loading destination taxonomy IDs for #{output_taxonomy}")
    YAML.load_file("data/integrations/#{output_taxonomy}/full_names.yml").each_with_object({}) do |category, hash|
      hash[category["full_name"]] = category["id"]
    end
  end

  def generate_missing_mappings_for_groups
    @unmapped_category_groups.each do |unmapped_category_group|
      input_taxonomy = unmapped_category_group[:input_taxonomy]
      output_taxonomy = unmapped_category_group[:output_taxonomy]
      index_name = output_taxonomy.gsub(%r{[/\-]}, "_")
      frame("Generating mappings for #{input_taxonomy} -> #{output_taxonomy}") do
        embedding_data = load_embedding_data(output_taxonomy)
        index_embedding_data(embedding_data:, index_name:)
        generate_and_evaluate_mappings_for_group(
          unmapped_category_group:,
          index_name:,
        )
      end
    end
  end

  def generate_mapping(
    source_category_id:,
    source_category_name:,
    index_name:,
    destination_taxonomy_ids_by_full_name:
  )
    logger.debug("Generating mapping for #{source_category_name}")
    category_embedding = get_embeddings(source_category_name)
    top_candidate = search_top_candidate(query_embedding: category_embedding, index_name:)
    destination_category_id = destination_taxonomy_ids_by_full_name[top_candidate]

    new_entry = {
      "input" => { "product_category_id" => source_category_id },
      "output" => { "product_category_id" => [destination_category_id.to_s] },
    }

    mapping_to_be_graded = {
      from_category_id: source_category_id,
      from_category: source_category_name,
      to_category_id: destination_category_id.to_s,
      to_category: top_candidate,
    }

    logger.debug("Grading mapping for #{source_category_name} -> #{top_candidate}")
    grading_result = grade_taxonomy_mapping(mapping_to_be_graded)

    { new_entry: new_entry, mapping_to_be_graded: mapping_to_be_graded, grading_result: grading_result }
  end

  def search_top_candidate(query_embedding:, index_name:)
    result = qdrant_client.points.search(
      collection_name: index_name,
      vector: query_embedding,
      with_payload: true,
      limit: 1,
    )
    result["result"].first["payload"][index_name]
  end

  def write_disagree_messages(disagree_messages)
    sys.write_file("tmp/mapping_update_message.txt") do |file|
      file.puts "❗AI Grader disagrees with the following mappings:"
      disagree_messages.each do |mapping|
        mapping.each { |key, value| file.puts "#{key}:#{value}" }
        file.puts
      end
    end
  end

  def grade_taxonomy_mapping(mapping)
    with_retries do
      response = openai_client.chat(
        parameters: {
          model: MAPPING_GRADER_GPT_MODEL,
          messages: [
            { role: "system", content: system_prompts_of_taxonomy_mapping_grader },
            { role: "user", content: [mapping].to_json },
          ],
          temperature: 0,
        },
      )
      JSON.parse(response.dig("choices", 0, "message", "content")).first["agree_with_mapping"]
    end
  end

  def get_embeddings(text)
    with_retries do
      response = openai_client.embeddings(
        parameters: {
          model: EMBEDDING_MODEL,
          input: text,
        },
      )
      response.dig("data", 0, "embedding")
    end
  end

  def with_retries
    retries = 0
    begin
      yield
    rescue StandardError => e
      retries += 1
      if retries <= MAX_RETRIES
        logger.debug("Received error: #{e.message}. Retrying (#{retries}/#{MAX_RETRIES})...")
        sleep(1)
        retry
      else
        logger.fatal("Failed after #{MAX_RETRIES} retries.")
        raise
      end
    end
  end

  def system_prompts_of_taxonomy_mapping_grader
    <<~CONTEXT
      You are a taxonomy mapping expert who evaluate the accuracy of product category mappings between two taxonomies.
      Your task is to review and grade the accuracy of the mappings, Yes or No, based on the following criteria:
      1. Mark a mapping as Yes, i.e. correct, if two categories of a mapping are highly relevant to each other and similar
        in terms of product type, function, or purpose.
        For example:
          - "Apparel & Accessories" and "Clothing, Shoes & Jewelry"
          - "Apparel & Accessories > Clothing > One-Pieces" and "Clothing, Shoes & Accessories > Women > Women's Clothing > Jumpsuits & Rompers"
      2. Mark a mapping as No, i.e. incorrect, if two categories of a mapping are irrevant to each other
        in terms of product type, function, or purpose.
        For example:
          - "Apparel & Accessories > Clothing > Dresses" and "Clothing, Shoes & Jewelry>Shoe, Jewelry & Watch Accessories"
          - "Apparel & Accessories" and "Clothing, Shoes & Jewelry>Luggage & Travel Gear"
      Note, the character ">" in a category name indicates the start of a new category level. For example:
      "sporting goods > exercise & fitness > cardio equipment"'s ancestor categories are "sporting goods > exercise & fitness" and "sporting goods".
      You will receive a list of mappings. Each mapping contains a from_category name and a to_category name.
      e.g. user's prompt in json format:
      [
        {
          "from_category_id": "111",
          "from_category": "Apparel & Accessories > Jewelry > Smart Watches",
          "to_category_id": "222",
          "to_category": "Clothing, Shoes & Jewelry>Men's Fashion>Men's Watches>Men's Smartwatches",
          },
        {
          "from_category_id": "333",
          "from_category": "Apparel & Accessories > Clothing > One-Pieces",
          "to_category_id": "444",
          "to_category": "Clothing, Shoes & Accessories > Women > Women's Clothing > Outfits & Sets",
          },
      ]
      You evaluate accuracy of every mapping and reply in the following format. Do not change the order of mappings in your reply.
      e.g. your response in json format:
      [
        {
          "from_category_id": "111",
          "from_category": "Apparel & Accessories > Jewelry > Smart Watches",
          "to_category_id": "222",
          "to_category": "Clothing, Shoes & Jewelry>Men's Fashion>Men's Watches>Men's Smartwatches",
          "agree_with_mapping": "Yes",
        },
        {
        "from_category_id": "333",
          "from_category": "Apparel & Accessories > Clothing > One-Pieces",
          "to_category_id": "444",
          "to_category": "Clothing, Shoes & Accessories > Women > Women's Clothing > Outfits & Sets",
          "agree_with_mapping": "No",
        },
      ]
    CONTEXT
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new(
      access_token: ENV["OPENAI_API_KEY"],
      uri_base: "https://openai-proxy.shopify.ai/v1",
      request_timeout: 10,
    )
  end

  def qdrant_client
    ensure_qdrant_server_running

    @qdrant_client ||= Qdrant::Client.new(url: "http://localhost:#{QDRANT_PORT}")
  end

  def ensure_qdrant_server_running
    return if system("lsof -i:#{QDRANT_PORT}", out: "/dev/null")

    command = "podman run -p #{QDRANT_PORT}:#{QDRANT_PORT} qdrant/qdrant"
    pid = Process.spawn(command, out: "/dev/null", err: "/dev/null")
    Process.detach(pid)
    logger.info("Started Qdrant server in the background with PID #{pid}.")
  end
end
