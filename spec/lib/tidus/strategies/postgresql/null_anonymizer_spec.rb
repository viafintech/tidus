# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::NullAnonymizer do
  it "returns NULL" do
    result = described_class.anonymize("foo", "bar")
    result.should == "NULL::unknown"
  end
end