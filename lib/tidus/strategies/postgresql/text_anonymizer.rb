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
          upper = ("A".."Z").to_a
          lower = ("a".."z").to_a
          result = base.split("").map do |letter|
            if letter == letter.upcase
              upper.sample
            else
              lower.sample
            end
          end
          result.join("")
        end
    end
  end
end