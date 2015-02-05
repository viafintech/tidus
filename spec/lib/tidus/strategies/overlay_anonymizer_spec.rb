require 'spec_helper'

describe Tidus::OverlayAnonymizer do
  context "postgresql" do
    before(:each) do
      ActiveRecord::Base.stub_chain(:connection, :instance_values)
                        .and_return({ "config" => {
                          :adapter => "postgresql"
                        } })
    end

    it "raises an exception if the start setting is missing" do
      expect {
        described_class.anonymize("foo", "bar", {})
      }.to raise_error("Missing option :start for OverlayAnonymizer on foo.bar")
    end

    it "raises an exception if the length setting is empty" do
      expect {
        described_class.anonymize("foo", "bar", { :start => 1 })
      }.to raise_error("Missing option :length for OverlayAnonymizer on foo.bar")
    end

    context "valid options" do
      before(:each) do
        @options = {
          :start => 20,
          :length => 8
        }
      end

      it "returns a string with an overlay function" do
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "\"overlay\"((foo.bar)::text, 'XXXXXXXX'::text, 20)"
      end

      it "uses the defined overlay character" do
        @options[:char] = 'c'
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "\"overlay\"((foo.bar)::text, 'cccccccc'::text, 20)"
      end

      it "uses the defined start and length character" do
        @options[:start]  = 4
        @options[:length] = 4
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "\"overlay\"((foo.bar)::text, 'XXXX'::text, 4)"
      end
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