# encoding: utf-8

require 'spec_helper'

describe Tidus::StaticAnonymizer do
  context "postgresql" do
    before(:each) do
      ActiveRecord::Base.stub_chain(:connection, :instance_values)
                        .and_return({ "config" => {
                          :adapter => "postgresql"
                        } })
    end

    it "raises an exception if the value setting is missing" do
      expect {
        described_class.anonymize("foo", "bar", {})
      }.to raise_error("Missing option :value for StaticAnonymizer on foo.bar")
    end

    it "returns the value that was provided" do
      described_class.anonymize("foo", "bar", { :value => "cookie"}).should == "'cookie'"
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