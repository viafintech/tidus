module Tidus
  module Postgresql
    class Sha256Anonymizer

      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"

        length = options[:length] || 64

        return "SUBSTR(ENCODE(DIGEST(#{name}, 'sha256')::TEXT, 'HEX'), 0, #{length.to_i + 1})"
      end

    end
  end
end
