module ActiveRecordAnonymize
  class NullAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        return "NULL::unknown"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end