# frozen_string_literal: true

class GenerateMissingMappingsCommand < ApplicationCommand
  UNSTABLE = "unstable"
  EMBEDDING_MODEL = "text-embedding-3-small"
  MAPPING_GRADER_GPT_MODEL = "gpt-4"

  usage do
    no_command
  end

  environment :openai_api_key do
    desc "OpenAI API key for mappings generation"
    required
  end

  environment :openai_url do
    desc "OpenAI API URL for mappings generation"
    default "https://openai-proxy.shopify.ai/v1" # TODO: we should probably not have this in this repo
  end

  environment :qdrant_url do
    desc "Qdrant API URL for embeddings search"
    default "http://localhost:6333"
  end

  option :shopify_version do
    desc "Target shopify taxonomy version"
    short "-V"
    long "--version string"
    default UNSTABLE
  end

  option :retries do
    desc "Number of retries for OpenAI API"
    short "-r"
    long "--retries integer"
    default 3
    convert :to_i
  end

  def execute
    frame("Generating missing mappings") do
      logger.headline("Target Shopify version: #{params[:version]}")
      logger.headline("OpenAI url: #{params[:openai_url]}")
      logger.headline("Qdrant url: #{params[:qdrant_url]}")

      find_unmapped_categories
      return if @unmapped_categories.empty?

      generate_missing_mappings
    end
  end

  private

  def find_unmapped_categories
    spinner("Finding Shopify categories that are unmapped") do
      all_shopify_ids = Set.new(Category.all.pluck(:id))
      mappings_by_output = MappingRule
        .where(input_version: "shopify/#{params[:shopify_version]}")
        .group_by(&:output_version)
      @unmapped_categories = mappings_by_output.filter_map do |output_taxonomy, mappings|
        found_shopify_ids = Set.new(mappings.map { _1.input.product_category_id.split("/").last })
        unmapped_ids = all_shopify_ids - found_shopify_ids
        id_name_map = Category.where(id: unmapped_ids).pluck(:id, :full_name).to_h
        next if id_name_map.empty?

        { output_taxonomy:, id_name_map: }
      end
    end
  end

  def generate_missing_mappings
    frame("Generating missing mappings") do
      @unmapped_categories.each do |unmapped_category|
        output_taxonomy = unmapped_category[:output_taxonomy]

        frame("Generating mappings to #{output_taxonomy}") do
          embedding_data = load_embedding_data(output_taxonomy)
          embedding_collection = output_taxonomy.gsub(%r{[/\-]}, "_")

          index_embedding_data(embedding_data:, embedding_collection:)
          generate_and_evaluate_mappings_for_group(unmapped_category:, embedding_collection:, )
        end
      end
    end
  end

  def load_embedding_data(output_taxonomy)
    spinner("Loading embeddings") do |sp|
      files = sys.glob("data/integrations/#{output_taxonomy}/embeddings/_*.txt")
      sp.update_title("Parsing #{files.size}} parts")

      files.each_with_object({}) do |partition, embedding_data|
        sys.read_file(partition).each_line do |line|
          word, vector_str = line.chomp.split(":", 2)
          vector = vector_str.split(", ").map { BigDecimal(_1).to_f }
          embedding_data[word] = vector
        end.tap { sp.update_title("Loaded embeddings") }
      end
    end
  end

  def index_embedding_data(embedding_data:, embedding_collection:)
    spinner("Indexing embeddings") do |sp|
      qdrant_client.collections.delete(collection_name: embedding_collection)
      qdrant_client.collections.create(
        collection_name: embedding_collection,
        vectors: { size: 1536, distance: "Cosine" },
      )

      points = embedding_data.map.with_index do |(key, value), index|
        {
          id: index + 1,
          vector: value,
          payload: { embedding_collection => key },
        }
      end

      points.each_slice(100) do |batch|
        qdrant_client.points.upsert(
          collection_name: embedding_collection,
          points: batch,
        )
      end
      sp.update_title("Indexed embeddings")
    end
  end

  def generate_and_evaluate_mappings_for_group(unmapped_category:, embedding_collection:)
    frame("Generating and evaluating mappings for each Shopify category") do
      destination_name_id_map = sys.parse_yaml(full_names_path(unmapped_category)).slice("full_name", "id")
      mapping_data = sys.parse_yaml(mapping_file_path(unmapped_category))
      disagree_messages = []

      unmapped_category[:id_name_map].each do |source_category_id, source_category_name|
        generated_mapping = generate_mapping(
          source_category_id:,
          source_category_name:,
          embedding_collection:,
          destination_name_id_map:,
        )

        mapping_data["rules"] << generated_mapping[:new_entry]
        disagree_messages << generated_mapping[:mapping_to_be_graded] if generated_mapping[:grading_result] == "No"
      end

      mapping_data["rules"].sort_by! { |rule| rule["input"]["product_category_id"] }
      sys.write_file(mapping_file_path(unmapped_category)) do |file|
        file.write(mapping_data.to_yaml)
      end

      write_disagree_messages(disagree_messages) if disagree_messages.any?
    end
  end

  def full_names_path(unmapped_category)
    "data/integrations/#{unmapped_category[:output_taxonomy]}/full_names.yml"
  end

  def mapping_file_path(unmapped_category)
    "data/integrations/#{unmapped_category[:output_taxonomy]}/mappings/from_shopify.yml"
  end

  def generate_mapping(source_category_id:, source_category_name:, embedding_collection:, destination_name_id_map: )
    category_embedding = request_embeddings(source_category_name)
    top_candidate = search_top_candidate(query_embedding: category_embedding, embedding_collection:)

    destination_category_id = destination_name_id_map[top_candidate].to_s
    mapping_to_be_graded = {
      from_category_id: source_category_id,
      from_category: source_category_name,
      to_category_id: destination_category_id,
      to_category: top_candidate,
    }
    grading_result = grade_taxonomy_mapping(mapping_to_be_graded)

    new_entry = {
      "input" => { "product_category_id" => source_category_id },
      "output" => { "product_category_id" => [destination_category_id] },
    }

    { new_entry:, mapping_to_be_graded:, grading_result: }
  end

  def request_embeddings(category_name)
    spinner.spin("Generating mapping for #{category_name}") do |sp|
      with_retries do
        response = openai_client.embeddings(
          parameters: {
            model: EMBEDDING_MODEL,
            input: category_name,
          },
        )
        response.dig("data", 0, "embedding")
      end
    end
  end

  def search_top_candidate(query_embedding:, embedding_collection:)
    result = qdrant_client.points.search(
      collection_name: embedding_collection,
      vector: query_embedding,
      with_payload: true,
      limit: 1,
    )
    result["result"].first["payload"][embedding_collection]
  end

  def grade_taxonomy_mapping(mapping)
    spinner.spin("Grading mapping for #{mapping[:from_category]} -> #{mapping[:to_category]}") do |sp|
      with_retries do
        response = openai_client.chat(
          parameters: {
            model: MAPPING_GRADER_GPT_MODEL,
            messages: [
              { role: "system", content: SYSTEM_PROMPT },
              { role: "user", content: [mapping].to_json },
            ],
            temperature: 0,
          },
        )
        sys.parse_json(response.dig("choices", 0, "message", "content")).first["agree_with_mapping"]
      end
    end
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

  def with_retries
    retries = 0
    begin
      yield
    rescue StandardError => e
      retries += 1
      if retries <= params[:retries]
        logger.debug("Received error: #{e.message}. Retrying (#{retries}/#{params[:retries]]})...")
        sleep(1)
        retry
      else
        logger.fatal("Failed after #{params[:retries]]} retries.")
        raise
      end
    end
  end

  SYSTEM_PROMPT = <<~PROMPT
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
  PROMPT

  def openai_client
    @openai_client ||= OpenAI::Client.new(
      access_token: params[:openai_api_key],
      uri_base: params[:openai_url],
      request_timeout: 10,
    )
  end

  def qdrant_client
    @qdrant_client ||= begin
      ensure_qdrant_server_running # TODO: Remove once handled by makefile
      Qdrant::Client.new(url: params[:qdrant_url])
    end
  end

  # TODO: move to makefile; ruby should not need to think abuot service setup
  def ensure_qdrant_server_running
    qdrant_port = URI.parse(params[:qdrant_url]).port
    return if system("lsof -i:#{qdrant_port}", out: "/dev/null")

    command = "podman run -p #{qdrant_port}:#{qdrant_port} qdrant/qdrant"
    pid = Process.spawn(command, out: "/dev/null", err: "/dev/null")
    Process.detach(pid)
    logger.info("Started Qdrant server in the background with PID #{pid}.")
  end
end
