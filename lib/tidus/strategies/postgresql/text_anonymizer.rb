module Tidus
  module Postgresql
    class TextAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZCßüäöÜÄÖ0123456789"
        return "translate((#{table_name}.#{column_name})::text, " +
               "'#{base}'::text, '#{generate_mapping(base)}'::text)"
      end

      private
        def self.generate_mapping(base)
          upper_and_nums = ("A".."Z").to_a + ('0'..'9').to_a
          lower = ("a".."z").to_a
          result = base.split("").map do |letter|
            if letter == letter.upcase
              upper_and_nums.sample
            else
              lower.sample
            end
          end
          result.join("")
        end
    end
  end
end
