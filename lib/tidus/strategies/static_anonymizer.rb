module Tidus
  class StaticAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        raise "Missing option :value for StaticAnonymizer on #{table_name}.#{column_name}" if options[:value].blank?

        return "'#{options[:value]}'"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end


