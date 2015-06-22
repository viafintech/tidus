# encoding: utf-8

module Tidus
  class BaseSelector
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]

      begin
        klass = Kernel.const_get("Tidus::#{adapter.camelize}::#{self.name.demodulize}")
        klass.anonymize(table_name, column_name, options)
      rescue NameError
        raise "#{self.name} not implemented for #{adapter}"
      end

    end
  end
end
