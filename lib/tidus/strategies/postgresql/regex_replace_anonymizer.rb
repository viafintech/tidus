module Tidus
  module Postgresql
    class RegexReplaceAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"

        raise "Missing option :pattern for RegexReplaceAnonymizer on #{name}" if options[:pattern].blank?

        return "REGEXP_REPLACE(#{name}, '#{options[:pattern]}', '#{options[:replacement]}')"
      end
    end
  end
end
