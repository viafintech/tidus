# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::RemoveJsonKeysAnonymizer do
  it "raises an exception if the pattern options is missing" do
    expect {
      described_class.anonymize("foo", "bar")
    }.to raise_error("Missing option :keys for RemoveJsonKeysAnonymizer on foo.bar")
  end

  it "returns regex replacement sql" do
    result = described_class.anonymize("foo", "bar", keys: [:abc])
    result.should ==
      "(SELECT concat('{', string_agg(to_json(\"key\") || ':' || \"value\", ','), '}')::json " +
      "FROM json_each(foo.bar::json) WHERE key <> 'abc')"

    result = described_class.anonymize("foo", "bar", keys: [:abc, :cde])
    result.should ==
      "(SELECT concat('{', string_agg(to_json(\"key\") || ':' || \"value\", ','), '}')::json " +
      "FROM json_each(foo.bar::json) WHERE key <> 'abc' AND key <> 'cde')"
  end
end
