module ActiveRecordAnonymize
  class CondAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        name = "#{table_name}.#{column_name}"

        if options[:value].blank?
          raise "Missing option :value for CondAnonymizer on #{column_name}"
        end

        type = options[:type] || "text"

        if options[:condition].blank? || options[:condition][:field].blank? ||
          options[:condition][:value].blank?
          raise "Missing option :condition for CondAnonymizer on #{column_name}"
        end

        cond_field = options[:condition][:field]
        cond_value = options[:condition][:value]
        cond_type  = options[:condition][:type] || "text"
        comparator = options[:condition][:comparator] || "="


        return "CASE WHEN ((#{cond_field})::#{cond_type} #{comparator} " +
               "'#{cond_value}'::#{cond_type}) THEN '#{options[:value]}'::#{type} " +
               "ELSE #{name} END"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end