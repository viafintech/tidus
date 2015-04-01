module Tidus
  module Sqlite3
    class NullAnonymizer
      def self.anonymize(table_name, column_name, options = {})
        return "NULL"
      end
    end
  end
end