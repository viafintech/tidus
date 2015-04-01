module Tidus
  module Postgresql
    class NullAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        return "NULL::unknown"
      end
    end
  end
end