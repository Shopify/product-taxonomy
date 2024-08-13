# frozen_string_literal: true

module StringTransformer
  class << self
    def generate_friendly_id(name)
      I18n.transliterate(name)
        .downcase
        .gsub(%r{[^a-z0-9\s\-_/\.\+#]}, "")
        .gsub(/[\s\-\.]+/, "_")
    end

    def generate_handle(text)
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
