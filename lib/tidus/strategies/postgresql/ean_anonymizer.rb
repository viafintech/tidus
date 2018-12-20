module Tidus
  module Postgresql
    class EanAnonymizer
      BASE_MAPPING          = '0123456789'.freeze
      DEFAULT_MAPPING_START = 1.freeze

      def self.anonymize(table_name, column_name, options = {})
        mapping_snippet = build_mapped_digit_snippet(column_name, options)

        query = <<-SQL
          (
            SELECT
              string_agg(new_digits.digit::TEXT, ''::TEXT)
            FROM (
              (
                SELECT
                  pos,
                  digit
                FROM (
                  #{mapping_snippet}
                ) AS where_sub
                ORDER BY pos ASC
              )
              UNION ALL
              (
                SELECT
                  LENGTH(#{column_name}::TEXT) AS pos,
                  (
                    10
                    -
                    (
                      (
                        SELECT
                          SUM(digit)
                        FROM (
                          #{mapping_snippet}
                        ) AS where_sub
                        WHERE pos % 2 = LENGTH(#{column_name}::TEXT) % 2
                      )
                      +
                      (
                        SELECT
                          SUM(digit)
                        FROM (
                          #{mapping_snippet}
                        ) AS where_sub
                        WHERE pos % 2 = (LENGTH(#{column_name}::TEXT) - 1) % 2
                      ) * 3
                    ) % 10
                  ) % 10 AS digit
              )
            ) new_digits
          )
          SQL

        return query.gsub!(/\n/, '').gsub!(/\ +/, ' ')
      end

      # Generates a new mapping if no cache_key is given
      # Generates a new mapping if the cache_key is unknown
      # Reuses the found mapping if the cache_key is known
      def self.retrieve_mapping(cache_key)
        @cached_mappings ||= {}
        mapping = @cached_mappings[cache_key]

        if mapping == nil
          mapping = {
            base:        BASE_MAPPING,
            replacement: BASE_MAPPING.split('').shuffle.join('')
          }
        end

        if cache_key != nil
          @cached_mappings[cache_key] = mapping
        end

        return mapping
      end

      def self.build_mapped_digit_snippet(column_name, options)
        substrings = build_digit_mapping(column_name, options)

        return <<-SQL
          SELECT
            *
          FROM (
            SELECT
              ROW_NUMBER() over () AS pos,
              digit::INT
            FROM (
              SELECT
                REGEXP_SPLIT_TO_TABLE(
                  #{substrings.join(' || ')},
                  ''
                ) AS digit
            ) AS sub
          ) AS sub
          WHERE pos < LENGTH(#{column_name}::TEXT)
        SQL
      end

      def self.build_digit_mapping(column_name, options)
        mapping = retrieve_mapping(options[:cache_key])

        options[:start] ||= DEFAULT_MAPPING_START

        # reduce length by 1 to take away the check digit
        total_length = "LENGTH(#{column_name}::TEXT) - 1"
        length = options[:length] || total_length

        substrings = []

        if options[:start] != DEFAULT_MAPPING_START
          substrings << build_substring_snippet(
                          column_name,
                          DEFAULT_MAPPING_START,
                          options[:start] - DEFAULT_MAPPING_START
                        )
        end

        translate_part = <<-SNIPPET
          TRANSLATE(
            #{build_substring_snippet(column_name, options[:start], length)},
            '#{mapping[:base]}',
            '#{mapping[:replacement]}'
          )
        SNIPPET

        substrings << translate_part.gsub(/\n/, '').gsub(/\ +/, ' ')

        if options[:length] != nil
          substrings << build_substring_snippet(
                          column_name,
                          "#{options[:start]} + #{options[:length]}",
                          "#{total_length} - #{options[:start]}"
                        )
        end

        return substrings
      end

      def self.build_substring_snippet(column_name, start, length)
        return "SUBSTRING(#{column_name}::TEXT, #{start}, #{length})"
      end
    end
  end
end
