module ActiveRecordAnonymize
  class KeyAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        return "\"overlay\"((#{table_name}.#{column_name})::text, " +
               "'XXXXXXXXXXX'::text, 30) AS #{table_name}.#{column_name}"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end