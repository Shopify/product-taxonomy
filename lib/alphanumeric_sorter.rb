# frozen_string_literal: true

module AlphanumericSorter
  class << self
    def sort(values, other_last: false)
      values.sort_by.with_index do |value, idx|
        [
          other_last && value.to_s.downcase == "other" ? 1 :  0,
          *normalize_value(value),
          idx
        ]
      end
    end

    def normalize_value(value)
      @normalized_values ||= {}
      @normalized_values[value] ||= begin
        if (numerical = value.match(RegexPattern::NUMERIC_PATTERN))
          [0, *normalize_numerical(numerical)]
        elsif (sequential = value.match(RegexPattern::SEQUENTIAL_TEXT_PATTERN))
          [1, *normalize_sequential(sequential)]
        else
          [1, normalize_text(value)]
        end
      end
    end

    private

    def normalize_numerical(match)
      [
        normalize_text(match[:primary_unit] || match[:secondary_unit]) || "",
        normalize_text(match[:seperator]) || "-",
        normalize_single_number(match[:primary_number]),
        normalize_single_number(match[:secondary_number]),
      ]
    end

    def normalize_sequential(match)
      [
        normalize_text(match[:primary_text]),
        normalize_single_number(match[:primary_step]),
        normalize_text(match[:primary_unit] || match[:secondary_unit]) || "",
        normalize_text(match[:seperator]) || "-",
        normalize_text(match[:secondary_text]),
        normalize_single_number(match[:secondary_step]),
        normalize_text(match[:trailing_text]),
      ]
    end

    def normalize_single_number(value)
      value = value.split.sum(&:to_r) if value&.include?("/")
      value.to_f
    end

    def normalize_text(value)
      return if value.nil?

      ActiveSupport::Inflector.transliterate(value.strip.downcase)
    end
  end

  module RegexPattern
    # matches numbers like -1, 5, 10.5, 3/4, 2 5/8
    SINGLE_NUMBER = %r{
      -?                          # Optional negative sign
      (?:
        \d+\.?\d*                 # Easy numbers like 5, 10.5
        |
        (?:\d+\s)?\d+/[1-9]+\d*   # Fractions like 3/4, 2 5/8
      )
    }x

    # matches units like sq.ft, km/h
    UNITS_OF_MEASURE = %r{
      [^\d\./\-]  # Matches any character not a digit, dot, slash or dash
      [^\-\d]*    # Matches any character not a dash or digit
    }x

    # String capturing is simple
    BASIC_TEXT = /\D+/
    SEPERATOR  = /[\p{Pd}x~]/

    # NUMERIC_PATTERN matches a primary number with optional units, and an optional range or dimension
    # with a secondary number and its optional units.
    NUMERIC_PATTERN = %r{
      ^\s*(?<primary_number>#{SINGLE_NUMBER})   # 1. Primary number
      \s*(?<primary_unit>#{UNITS_OF_MEASURE})?  # 2. Optional units for primary number
      (?:                                       # Optional range or dimension
        \s*(?<seperator>#{SEPERATOR})               # 3. Separator
        \s*(?<secondary_number>#{SINGLE_NUMBER})    # 4. Secondary number
        \s*(?<secondary_unit>#{UNITS_OF_MEASURE})?  # 5. Optional units for secondary number
      )?
      \s*$
    }x

    # SEQUENTIAL_TEXT_PATTERN matches a primary non-number string, an optional step, and optional units,
    # followed by an optional range or dimension with a secondary non-number string, an optional step,
    # and optional units, and finally an optional trailing text.
    SEQUENTIAL_TEXT_PATTERN = %r{
      ^\s*(?<primary_text>#{BASIC_TEXT})            # 1. Primary non-number string
      \s*(?<primary_step>#{SINGLE_NUMBER})?         # 2. Optional step
      \s*(?<primary_unit>#{UNITS_OF_MEASURE})?      # 3. Optional units for primary number
      (?:                                           # Optional range or dimension
        \s*(?<seperator>#{SEPERATOR})                 # 4. Separator -- capturing allows us to group ranges and dimensions
        \s*(?<secondary_text>#{BASIC_TEXT})?          # 5. Optional secondary non-number string
        \s*(?<secondary_step>#{SINGLE_NUMBER})        # 6. Secondary step
        \s*(?<secondary_unit>#{UNITS_OF_MEASURE})?    # 7. Optional units for secondary number
      )?
      \s*(?<trailing_text>.*)?$                     # 8. Optional trailing text
    }x
  end
end
