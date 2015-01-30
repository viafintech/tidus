module ActiveRecordAnonymize
  class OverlayAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        name = "#{table_name}.#{column_name}"

        raise "Missing option :start for OverlayAnonymizer on #{name}" if options[:start].blank?
        raise "Missing option :length for OverlayAnonymizer on #{name}" if options[:length].blank?

        overlay_char = options[:char] || "X"
        overlay = overlay_char * options[:length]
        return "\"overlay\"((#{name})::text, " +
               "'#{overlay}'::text, #{options[:start]})"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end