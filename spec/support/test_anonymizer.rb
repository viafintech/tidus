module ActiveRecordAnonymize
  class TestAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      return "'test'::text"
    end
  end
end