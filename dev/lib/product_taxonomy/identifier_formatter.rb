# frozen_string_literal: true

module ProductTaxonomy
  module IdentifierFormatter
    class << self
      def format_friendly_id(text)
        I18n.transliterate(text)
          .downcase
          .gsub(%r{[^a-z0-9\s\-_/\.\+#]}, "")
          .gsub(/[\s\-\.]+/, "_")
      end

      def format_handle(text)
        I18n.transliterate(text)
          .downcase
          .gsub(%r{[^a-z0-9\s\-_/\+#]}, "")
          .gsub("+", "-plus-")
          .gsub("#", "-hashtag-")
          .gsub("/", "-")
          .gsub(/[\s\.]+/, "-")
          .gsub("_-_", "-")
          .gsub(/(?<!_)_(?!_)/, "-")
          .gsub(/--+/, "-")
          .gsub(/\A-+|-+\z/, "")
      end
    end
  end
end
