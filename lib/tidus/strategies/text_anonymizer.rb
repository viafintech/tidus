module Tidus
  class TextAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]

      begin
        klass = "Tidus::#{adapter.camelize}::#{self.name.demodulize}".constantize
        klass.anonymize(table_name, column_name, options)
      rescue NameError
        raise "#{self.name} not implemented for #{adapter}"
      end

    end
  end
end