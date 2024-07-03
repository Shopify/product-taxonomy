# frozen_string_literal: true

GEM_AVAILABLE = begin
  require "filter_values_sorter"
  true
rescue LoadError
  false
end

class ValueSorter
  CUSTOM_SORT_SIZE_ATTRIBUTES = [
    "accessory-size",
    "ball-size",
    "beater-head-size",
    "bedding-size",
    "bell-size",
    "compatible-shoe-size",
    "compatible-mattress-size",
    "desk-size",
    "diaper-size",
    "dog-diaper-size",
    "shoe-size",
    "size",
    "suitable-for-breed-size",
  ].freeze

  class << self
    def sort_values_for_attribute(attribute_handle, values)
      if CUSTOM_SORT_SIZE_ATTRIBUTES.include?(attribute_handle)
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
