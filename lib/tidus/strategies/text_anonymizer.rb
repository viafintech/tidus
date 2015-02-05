module Tidus
  class TextAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZCßüäöÜÄÖ"
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        return "translate((#{table_name}.#{column_name})::text, " +
               "'#{base}'::text, '#{generate_mapping(base)}'::text)"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
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