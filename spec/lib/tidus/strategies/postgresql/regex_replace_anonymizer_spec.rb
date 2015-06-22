# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::RegexReplaceAnonymizer do
  it "raises an exception if the pattern options is missing" do
    expect {
      described_class.anonymize("foo", "bar")
    }.to raise_error("Missing option :pattern for RegexReplaceAnonymizer on foo.bar")
  end

  it "raises an exception if the replacement options is missing" do
    expect {
      described_class.anonymize("foo", "bar", :pattern => "1234")
    }.to raise_error("Missing option :replacement for RegexReplaceAnonymizer on foo.bar")
  end

  it "returns regex replacement sql" do
    result = described_class.anonymize("foo", "bar", :pattern => "1234", :replacement => "a")
    result.should == "REGEXP_REPLACE(foo.bar, '1234', 'a')"
  end
end
