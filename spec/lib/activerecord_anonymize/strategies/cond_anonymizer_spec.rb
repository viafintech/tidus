require 'spec_helper'

describe ActiveRecordAnonymize::CondAnonymizer do
  context "postgresql" do
    before(:each) do
      ActiveRecord::Base.stub_chain(:connection, :instance_values)
                        .and_return({ "config" => {
                          :adapter => "postgresql"
                        } })
    end

    it "raises an exception if the conditions setting is missing" do
      expect {
        described_class.anonymize("foo", "bar", {})
      }.to raise_error("Missing option :conditions for CondAnonymizer on foo.bar")
    end

    it "raises an exception if the conditions setting is empty" do
      expect {
        described_class.anonymize("foo", "bar", { :conditions => [] })
      }.to raise_error("Missing option :conditions for CondAnonymizer on foo.bar")
    end

    context "valid conditions" do
      before(:each) do
        @options = {
          :conditions => [{
            :column     => "bar",
            :value      => "cookie",
            :result     => "123"
          },{
            :column     => "baz",
            :value      => "keks",
            :result     => "567"
          }]
        }
      end

      [:column, :value, :result].each do |param|
        it "raises an exception if any condition misses the #{param} parameters" do
          @options[:conditions].last.delete(param)
          expect {
            described_class.anonymize("foo", "bar", @options)
          }.to raise_error(":#{param} for condition must be set")
        end
      end

      it "generates a string with each conditions as a case" do
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "CASE WHEN ((foo.bar)::text = 'cookie'::text) " +
                         "THEN '123'::text " +
                         "WHEN ((foo.baz)::text = 'keks'::text) " +
                         "THEN '567'::text ELSE foo.bar::text END"
      end

      it "works with a hash for conditions" do
        @options[:conditions] = @options[:conditions].last
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "CASE WHEN ((foo.baz)::text = 'keks'::text) " +
                         "THEN '567'::text ELSE foo.bar::text END"
      end

      it "uses the default as ELSE case if set" do
        @options[:default] = "some value"
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "CASE WHEN ((foo.bar)::text = 'cookie'::text) " +
                         "THEN '123'::text " +
                         "WHEN ((foo.baz)::text = 'keks'::text) " +
                         "THEN '567'::text ELSE 'some value'::text END"
      end

      it "uses casts the returned value to another" do
        @options[:default] = "1"
        @options[:result_type] = "integer"
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "CASE WHEN ((foo.bar)::text = 'cookie'::text) " +
                         "THEN '123'::integer " +
                         "WHEN ((foo.baz)::text = 'keks'::text) " +
                         "THEN '567'::integer ELSE '1'::integer END"
      end

      it "uses the specified type for value comparison" do
        @options[:conditions].first[:type] = "integer"
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "CASE WHEN ((foo.bar)::integer = 'cookie'::integer) " +
                         "THEN '123'::text " +
                         "WHEN ((foo.baz)::text = 'keks'::text) " +
                         "THEN '567'::text ELSE foo.bar::text END"
      end

      it "uses the specified comparison operator" do
        @options[:conditions].first[:comparator] = ">"
        result = described_class.anonymize("foo", "bar", @options)
        result.should == "CASE WHEN ((foo.bar)::text > 'cookie'::text) " +
                         "THEN '123'::text " +
                         "WHEN ((foo.baz)::text = 'keks'::text) " +
                         "THEN '567'::text ELSE foo.bar::text END"
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