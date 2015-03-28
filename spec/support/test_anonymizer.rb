# encoding: utf-8

module Tidus
  class TestAnonymizer
    def self.anonymize(table_name, column_name, options = {})
      return "'test'::text"
    end
  end
end