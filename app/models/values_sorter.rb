# frozen_string_literal: true

GEM_AVAILABLE = begin
  require "filter_values_sorter"
  true
rescue LoadError
  false
end

class ValuesSorter
  CUSTOM_SORT_SIZE_ATTRIBUTES = [
    "size",
    "bedding-size",
    "suitable-for-breed-size",
    "shoe-size",
    "ball-size",
    "diaper-size",
    "accessory-size",
  ].freeze

  class << self
    def sort_values_for_attribute(attribute, values)
      if CUSTOM_SORT_SIZE_ATTRIBUTES.include?(attribute)
        sort_values(values, filter_name: "size")
      else
        sort_values(values)
      end
    end

    def sort_values(values, filter_name: nil)
      return sort_other_last(values) unless GEM_AVAILABLE

      sorted = FilterValuesSorter.sort(values.to_a, filter_name: filter_name, sort_by: :name)

      sort_other_last(sorted)
    end

    def sort_other_last(values)
      values.partition { |value| value.name.downcase != "other" }.flatten
    end
  end
end
