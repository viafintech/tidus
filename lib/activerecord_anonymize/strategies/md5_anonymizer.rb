module ActiveRecordAnonymize
  class Md5Anonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        name = "#{table_name}.#{column_name}"
        options[:length] ||= 15

        return "CASE WHEN ((#{name})::text ~~ '%@%'::text) " +
               "THEN (((\"left\"(md5((#{name})::text), #{options[:length]}) || '@'::text) " +
                "|| split_part((#{name})::text, '@'::text, 2)))::character varying " +
                "ELSE #{name} END AS #{name}"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end


