module Tidus
  class CondAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        name = "#{table_name}.#{column_name}"

        type = options[:result_type] || "text"
        default = options[:default].nil? ? "#{name}::#{type}" : "'#{options[:default]}'::#{type}"

        if options[:conditions].blank?
          raise "Missing option :conditions for CondAnonymizer on #{name}"
        elsif options[:conditions].kind_of?(Array)
          conditions = options[:conditions]
        else
          conditions = [options[:conditions]]
        end

        command = "CASE "

        conditions.each do |cond|
          raise ":column for condition must be set" if cond[:column].blank?
          raise ":value for condition must be set" if cond[:value].nil?
          raise ":result for condition must be set" if cond[:result].nil?
          cond_column = cond[:column]
          cond_value  = cond[:value]
          cond_type   = cond[:type] || "text"
          comparator  = cond[:comparator] || "="
          cond_result = cond[:result]

          command += "WHEN ((#{table_name}.#{cond_column})::#{cond_type} #{comparator} " +
                     "'#{cond_value}'::#{cond_type}) THEN '#{cond_result}'::#{type} "
        end

        command += "ELSE #{default} END"

        return command
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end