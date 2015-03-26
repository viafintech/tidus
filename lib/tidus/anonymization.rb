# encoding: utf-8

module Tidus
	module Anonymization
    def view_postfix
      @view_postfix || "anonymized"
    end

    def view_postfix=(val)
      @view_postfix = val
    end

    def view_name
      @view_name || "#{table_name}_#{view_postfix}"
    end

    def view_name=(val)
      @view_name = val
    end

    def view_columns
      @view_columns ||= {}
      default_view_columns.merge(@view_columns)
                          .map{ |k,v| ["#{v} AS #{k}"] }
                          .flatten
    end

    def default_view_columns
      defaults = {}
      column_names.each do |column|
        defaults[column.to_sym] = "#{table_name}.#{column}"
      end
      defaults
    end

    def anonymizes(*attributes)
      @view_columns ||= {}

      options = attributes.extract_options!.dup
      columns = attributes - [options]

      raise ArgumentError, "You need to supply at least one attribute" if attributes.empty?
      raise ArgumentError, "You need to supply a strategy" if options[:strategy].blank?

      columns.each do |column|
        key = options[:strategy].to_s.camelize

        begin
          if key.include?('::')
            klass = key.constantize
          else
            klass = const_get("Tidus::#{key}Anonymizer")
          end
        rescue NameError
          raise ArgumentError, "Unknown anonymizer: '#{key}'"
        end

        @view_columns[column.to_sym] = klass.anonymize(table_name, column, options)
      end
    end

	end
end

ActiveRecord::Base.extend Tidus::Anonymization