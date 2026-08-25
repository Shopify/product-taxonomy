# frozen_string_literal: true

module ProductTaxonomy
  class DumpDisclosuresCommand < Command
    def execute
      logger.info("Dumping disclosures...")

      load_taxonomy

      path = File.expand_path("disclosures.yml", ProductTaxonomy.data_path)
      FileUtils.mkdir_p(File.dirname(path))

      existing = File.exist?(path) ? File.read(path) : nil
      data = Serializers::Disclosure::Data::DataSerializer.serialize_all
      File.write(path, dump_preserving_comments(data, existing))

      logger.info("Updated `#{path}`")
    end

    private

    # `YAML.dump` discards comments, which would wipe the hand-written header
    # and section comments from the data file. Re-attach each comment/blank-line
    # block from the existing file to the entry that follows it (keyed by
    # disclosure id). Blocks preceding an entry that no longer exists are
    # dropped.
    def dump_preserving_comments(data, existing)
      dumped = YAML.dump(data, line_width: -1)
      return dumped if existing.nil?

      blocks = comment_blocks_by_id(existing)
      output = +""
      dumped.each_line.with_index do |line, index|
        next if index.zero? && line == "---\n" && blocks[:header]&.include?("---\n")

        if (id = line[/\A- id: (\d+)$/, 1])
          output << blocks.delete(:header).to_s if blocks[:header]
          output << blocks.delete(id).to_s
        end
        output << line
      end
      output
    end

    # @return [Hash] comment/blank-line blocks keyed by the id of the entry
    #   that follows them. The file header (doc marker + leading comments) is
    #   keyed by :header.
    def comment_blocks_by_id(existing)
      blocks = {}
      buffer = +""
      existing.each_line do |line|
        if line.start_with?("#") || line.strip.empty? || line == "---\n"
          buffer << line
        elsif (id = line[/\A- id: (\d+)$/, 1])
          if blocks.key?(:header)
            blocks[id] = buffer unless buffer.empty?
          else
            # The block before the first entry holds the file header and,
            # possibly, that entry's own section comment — split them at the
            # last blank line so the section comment stays tied to the entry.
            header, entry_block = split_header(buffer)
            blocks[:header] = header # mark header as consumed even if empty
            blocks[id] = entry_block unless entry_block.empty?
          end
          buffer = +""
        else
          buffer = +""
        end
      end
      blocks.compact
    end

    # @return [Array(String, String)] the header portion (through the last
    #   blank line) and the remaining block belonging to the first entry.
    def split_header(buffer)
      lines = buffer.lines
      last_blank = lines.rindex { |line| line.strip.empty? }
      return [buffer, ""] if last_blank.nil? # no separator — treat it all as header

      [lines[..last_blank].join, lines[(last_blank + 1)..].join]
    end
  end
end
