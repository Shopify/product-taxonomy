# frozen_string_literal: true

module ValueSorter
  class << self
    def sort(values, locale: "en")
      if values.first.position.present?
        values.sort_by(&:position)
      else
        sort_by_localized_name(values, locale:)
      end
    end

    private

    def sort_by_localized_name(values, locale:)
      values.sort_by.with_index do |value, idx|
        [
          value.name(locale: "en").downcase == "other" ? 1 :  0,
          *AlphanumericSorter.normalize_value(value.name(locale:)),
          idx
        ]
      end
    end
  end
end
