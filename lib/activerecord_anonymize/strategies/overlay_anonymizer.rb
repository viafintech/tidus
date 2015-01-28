module ActiveRecordAnonymize
  class OverlayAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      adapter = ActiveRecord::Base.connection.instance_values["config"][:adapter]
      case adapter
      when "postgresql"
        raise "Missing option :start for OverlayAnonymizer on #{column_name}" if options[:start].blank?
        return "\"overlay\"((#{table_name}.#{column_name})::text, " +
               "'XXXXXXXXXXX'::text, #{options[:start]})"
      else
        raise "#{self.name} not implemented for #{adapter}"
      end
    end
  end
end