# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::TextAnonymizer do
  it "returns an SQL statement with a randomly generated mapping" do
    result = described_class.anonymize('foo', 'bar')
    base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZCßüäöÜÄÖ"
    result.should match(
      /translate\(\(foo\.bar\)::text, '#{base}'::text, '[A-Za-z0-9ÄÖÜäöü]{60}'::text\)/)
  end
end