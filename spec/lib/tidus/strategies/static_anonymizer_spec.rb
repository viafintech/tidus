# encoding: utf-8

require 'spec_helper'

describe Tidus::StaticAnonymizer do
  it "raises an exception if the value setting is missing" do
    expect {
      described_class.anonymize("foo", "bar", {})
    }.to raise_error("Missing option :value for StaticAnonymizer on foo.bar")
  end

  it "returns the value that was provided" do
    described_class.anonymize("foo", "bar", { :value => "cookie"}).should == "'cookie'"
  end
end