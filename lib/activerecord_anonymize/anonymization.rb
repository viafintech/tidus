module ActiveRecord
	module Anonymization
    def anon_postfix
      @anon_postfix || "anonymized"
    end

    def anon_postfix=(val)
      @anon_postfix = val
    end

    def view_name
      @view_name || "#{table_name}_#{anon_postfix}"
    end

    def view_name=(val)
      @view_name = val
    end

    def anonymize(*attributes)
      # defaults = attributes.extract_options!.dup
      # validations = defaults.slice!(*_anonymize_default_keys)

      # raise ArgumentError, "You need to supply at least one attribute" if attributes.empty?
      # raise ArgumentError, "You need to supply at least one validation" if validations.empty?

      # defaults[:attributes] = attributes

      # validations.each do |key, options|
      #   next unless options
      #   key = "#{key.to_s.camelize}Validator"

      #   begin
      #     validator = key.include?('::') ? key.constantize : const_get(key)
      #   rescue NameError
      #     raise ArgumentError, "Unknown validator: '#{key}'"
      #   end

      #   anonymize_with(validator, defaults.merge(_parse_validates_options(options)))
      # end
    end

	end
end

ActiveRecord::Base.extend ActiveRecord::Anonymization