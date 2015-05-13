module Tidus
  module Postgresql
    class CondAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"

        # If options is edited on a deeper level .dup has to be replaced by marshal dump/load
        options = options.dup
        options[:result_type] ||= "text"
        type = options[:result_type]

        if options[:default] && options[:default_strategy]
          raise "CondAnonymizer: Only one of default and default_strategy can be used"
        end

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
          raise ":value for condition must be set"  if cond[:value].nil?
          raise ":result for condition must be set" if cond[:result].nil?
          cond_column = cond[:column]
          cond_value  = cond[:value]
          cond_type   = cond[:type]       || "text"
          comparator  = cond[:comparator] || "="
          cond_result = cond[:result]

          command += "WHEN ((#{table_name}.#{cond_column})::#{cond_type} #{comparator} " +
                     "'#{cond_value}'::#{cond_type}) THEN '#{cond_result}'::#{type} "
        end

        command += "ELSE #{self.default(table_name, column_name, options)} END"

        return command
      end

      def self.default(table_name, column_name, options)
        type = options[:result_type]

        value = if options[:default_strategy]
          klass = self.anonymizer(options[:default_strategy])
          klass.anonymize(table_name, column_name, {})
        elsif options[:default]
          "'#{options[:default]}'::#{type}"
        else
          "#{table_name}.#{column_name}::#{type}"
        end
      end

      def self.anonymizer(name)
        begin
          klass = Kernel.const_get("Tidus::Postgresql::#{name.to_s.camelize}Anonymizer")
        rescue NameError
          raise "default_strategy '#{name}' not implemented for Postgresql"
        end
      end
    end
  end
end
