module Tidus
  module Postgresql
    class EmailAnonymizer

      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"
        length = options[:length] || 15
        anonymize_domain = options[:anonymize_domain] || false

        return "CASE WHEN ((#{name})::text ~~ '%@%'::text) " +
               "THEN (((\"left\"(md5((#{name})::text), #{length}) || '@'::text) " +
                "|| #{domain_part(name, anonymize_domain, length)}))::character varying " +
                "ELSE #{name} END"
      end

      def self.domain_part(name, anonymize_domain, length)
        if anonymize_domain
          return "(\"left\"(md5(split_part((#{name})::text, '@'::text, 2)::text), #{length}) " +
                 "|| '.com')"
        end

        return "split_part((#{name})::text, '@'::text, 2)"
      end

    end
  end
end
