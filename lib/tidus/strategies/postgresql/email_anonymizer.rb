module Tidus
  module Postgresql
    class EmailAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"
        options[:length] ||= 15

        return "CASE WHEN ((#{name})::text ~~ '%@%'::text) " +
               "THEN (((\"left\"(md5((#{name})::text), #{options[:length]}) || '@'::text) " +
                "|| split_part((#{name})::text, '@'::text, 2)))::character varying " +
                "ELSE #{name} END"
      end
    end
  end
end
