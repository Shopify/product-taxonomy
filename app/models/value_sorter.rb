# frozen_string_literal: true

# Module for sorting an attribute's values alphanumerically by their localized name
module ValueSorter
  class << self
    def sort(values, locale: "en")
      if values.first.position.present?
        sort_by_position(values)
      else
        sort_by_localized_name(values, locale: locale)
      end
    end

    private

    def sort_by_position(values)
      values.sort_by(&:position)
    end

    def sort_by_localized_name(values, locale: "en")
      sorted_values = values.sort do |value_a, value_b|
        a_name = value_a.name(locale: locale)
        b_name = value_b.name(locale: locale)

        compare(a_name, b_name)
      end

      other_values, normal_values = sorted_values.partition { |value| value.name.downcase == "other" }

      normal_values + other_values
    end

    def compare(value1, value2)
      (normalize_value(value1) <=> normalize_value(value2)) || 0
    end

    def normalize_value(value)
      @normalized_values ||= {}
      @normalized_values[value] ||= begin
        numerical = value.match(RegexPattern::NUMERIC_PATTERN)
        sequential = value.match(RegexPattern::SEQUENTIAL_TEXT_PATTERN)

        if numerical
          [0, *normalize_numerical(numerical)]
        elsif sequential
          [1, *normalize_sequential(sequential)]
        else
          [1, normalize_text(value)]
        end
      end
    end

    def normalize_numerical(match)
      [
        normalize_text(match[:p_unit] || match[:s_unit]) || "",
        normalize_text(match[:sep]) || "-",
        normalize_single_number(match[:p_value]),
        normalize_single_number(match[:s_value]) || 0,
      ]
    end

    def normalize_sequential(match)
      [
        normalize_text(match[:p_text]),
        normalize_single_number(match[:p_step]) || 0,
        normalize_text(match[:p_unit] || match[:s_unit]) || "",
        normalize_text(match[:sep]) || "-",
        normalize_text(match[:s_text]),
        normalize_single_number(match[:s_step]) || 0,
        normalize_text(match[:t_text]),
      ]
    end

    def normalize_single_number(value)
      return if value.nil?

      if value.include?("/")
        parts = value.split(" ")
        parts.length > 1 ? parts[0].to_f + Rational(parts[1]).to_f : Rational(parts[0]).to_f
      else
        value.to_f
      end
    end

    def normalize_text(value)
      ActiveSupport::Inflector.transliterate(value.strip.downcase) if value
    end
  end
end
