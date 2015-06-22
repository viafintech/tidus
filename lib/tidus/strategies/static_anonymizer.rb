# encoding: utf-8

module Tidus
  class StaticAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      raise "Missing option :value for StaticAnonymizer on #{table_name}.#{column_name}" if options[:value].blank?
      type = options[:type] || "unknown"

      return "'#{options[:value]}'::#{type}"
    end
  end
end
