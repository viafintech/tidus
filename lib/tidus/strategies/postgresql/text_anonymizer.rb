module Tidus
  module Postgresql
    class TextAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZCßüäöÜÄÖ"
        return "translate((#{table_name}.#{column_name})::text, " +
               "'#{base}'::text, '#{generate_mapping(base)}'::text)"
      end

      private
        def self.generate_mapping(base)
          result = ""
          base.split("").each do |letter|
            if letter == letter.upcase
              result += ("A".."Z").to_a.shuffle.first
            else
              result += ("a".."z").to_a.shuffle.first
            end
          end
          result
        end
    end
  end
end