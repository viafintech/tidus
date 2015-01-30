require 'spec_helper'

describe ActiveRecordAnonymize::TextAnonymizer do
  context "postgresql" do
    before(:each) do
      ActiveRecord::Base.stub_chain(:connection, :instance_values)
                        .and_return({ "config" => {
                          :adapter => "postgresql"
                        } })
    end

    it "returns an SQL statement with a randomly generated mapping" do
      result = described_class.anonymize('foo', 'bar')
      base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZCßüäöÜÄÖ"
      result.should match(
        /translate\(\(foo\.bar\)::text, '#{base}'::text, '[A-Za-z0-9ÄÖÜäöü]{60}'::text\)/)
    end
  end

  context "else" do
    before(:each) do
      ActiveRecord::Base.stub_chain(:connection, :instance_values)
                        .and_return({ "config" => {
                          :adapter => "anything"
                        } })
    end

    it "raises an exception if there is no matching implementation" do
      expect {
        described_class.anonymize("foo", "bar")
      }.to raise_error("#{described_class} not implemented for anything")
    end
  end
end