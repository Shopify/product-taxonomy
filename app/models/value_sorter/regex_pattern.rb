# frozen_string_literal: true

module ValueSorter
  # Contains regex patterns for matching value strings in order to properly sort them alphanumerically.
  module RegexPattern
    # SINGLE_NUMBER_PATTERN matches numbers like -1, 5, 10.5, 3/4, 2 5/8
    SINGLE_NUMBER_PATTERN = %r{
      -?                          # Optional negative sign
      (?:                         # Start group
        \d+\.?\d*                 # Matches numbers like 5, 10.5
        |                         # OR
        (?:\d+\s)?\d+/[1-9]+\d*   # Matches fractions like 3/4, 2 5/8
      )                           # End group
    }x

    NON_NUMBER_PATTERN = /\D+/ # Non-numeric characters

    # NUMBER_UNITS_PATTERN matches units that begin with characters absent in SINGLE_NUMBER_PATTERN: sq.ft, km/h
    NUMBER_UNITS_PATTERN = %r{
      [^\d\./\-]              # Matches any character not a digit, dot, slash or dash
      [^\-\d]*                # Matches any character not a dash or digit
    }x

    # NUMERIC_PATTERN matches a primary number with optional units, and an optional range or dimension
    # with a secondary number and its optional units.
    NUMERIC_PATTERN = %r{
      ^\s*                                    # Start of line, optional spaces
      (?<p_value>#{SINGLE_NUMBER_PATTERN})    # 1. Primary number
      \s*                                     # Optional spaces
      (?<p_unit>#{NUMBER_UNITS_PATTERN})?     # 2. Optional units for primary number
      (?:                                     # Start group for optional range or dimension
        \s*                                   # Optional spaces
        (?<sep>[\p{Pd}x~])                    # 3. Separator
        \s*                                   # Optional spaces
        (?<s_value>#{SINGLE_NUMBER_PATTERN})  # 4. Secondary number
        \s*                                   # Optional spaces
        (?<s_unit>#{NUMBER_UNITS_PATTERN})?   # 5. Optional units for secondary number
      )?                                      # End group for optional range or dimension
      \s*                                     # Optional spaces
      $                                       # End of line
    }x

    # SEQUENTIAL_TEXT_PATTERN matches a primary non-number string, an optional step, and optional units,
    # followed by an optional range or dimension with a secondary non-number string, an optional step,
    # and optional units, and finally an optional trailing text.
    SEQUENTIAL_TEXT_PATTERN = %r{
      ^\s*(?<p_text>#{NON_NUMBER_PATTERN})       # 1. Primary non-number string
      \s*(?<p_step>#{SINGLE_NUMBER_PATTERN})?    # 2. Optional step
      \s*(?<p_unit>#{NUMBER_UNITS_PATTERN})?     # 3. Optional units for primary number
      (?:                                        # -  Optional range or dimension
        \s*(?<sep>[\p{Pd}x~])                    # 4. Separator -- capturing allows us to group ranges and dimensions
        \s*(?<s_text>#{NON_NUMBER_PATTERN})?     # 5. Optional secondary non-number string
        \s*(?<s_step>#{SINGLE_NUMBER_PATTERN})   # 6. Secondary step
        \s*(?<s_unit>#{NUMBER_UNITS_PATTERN})?   # 7. Optional units for secondary number
      )?
      \s*(?<t_text>.*)?$                         # 8. Optional trailing text
    }x
  end
end
