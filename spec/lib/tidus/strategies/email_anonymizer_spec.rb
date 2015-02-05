require 'spec_helper'

describe Tidus::EmailAnonymizer do
  context "postgresql" do
    before(:each) do
      ActiveRecord::Base.stub_chain(:connection, :instance_values)
                        .and_return({ "config" => {
                          :adapter => "postgresql"
                        } })
    end

    it "returns a statement that replaces the user part of an email address" do
      result = described_class.anonymize("foo", "bar")
      result.should == "CASE WHEN ((foo.bar)::text ~~ '%@%'::text) " +
              "THEN (((\"left\"(md5((foo.bar)::text), 15) || '@'::text) " +
              "|| split_part((foo.bar)::text, '@'::text, 2)))::character varying " +
              "ELSE foo.bar END"
    end

    it "allows setting another length for the user part" do
      result = described_class.anonymize("foo", "bar", { :length => 10 })
      result.should == "CASE WHEN ((foo.bar)::text ~~ '%@%'::text) " +
              "THEN (((\"left\"(md5((foo.bar)::text), 10) || '@'::text) " +
              "|| split_part((foo.bar)::text, '@'::text, 2)))::character varying " +
              "ELSE foo.bar END"
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