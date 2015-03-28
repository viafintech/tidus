module Tidus
  module Postgresql
    class OverlayAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        name = "#{table_name}.#{column_name}"

        raise "Missing option :start for OverlayAnonymizer on #{name}" if options[:start].blank?
        raise "Missing option :length for OverlayAnonymizer on #{name}" if options[:length].blank?

        overlay_char = options[:char] || "X"
        overlay = overlay_char * options[:length]
        return "\"overlay\"((#{name})::text, " +
               "'#{overlay}'::text, #{options[:start]})"
      end
    end
  end
end