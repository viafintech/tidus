# encoding: utf-8

require 'spec_helper'

describe Tidus::Sqlite3::NullAnonymizer do
  it "returns NULL" do
    result = described_class.anonymize("foo", "bar")
    result.should == "NULL"
  end
end