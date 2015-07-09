# encoding: utf-8

module Tidus
  module Postgresql
    class RemoveJsonKeysAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"

        raise "Missing option :keys for RemoveJsonKeysAnonymizer on #{name}" if options[:keys].blank?

        removed_keys = options[:keys].map { |k| "key <> '#{k}'" }.join(" AND ")

        return "(SELECT concat('{', string_agg(to_json(\"key\") || ':' || \"value\", ','), '}')::json " +
               "FROM json_each(#{name}::json) WHERE #{removed_keys})"
      end
    end
  end
end
