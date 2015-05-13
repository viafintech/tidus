# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::CondAnonymizer do
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

    it 'raises an exception if both default and default_strategy are specified' do
      @options[:default] = "some value"
      @options[:default_strategy] = :email
      expect {
        described_class.anonymize("foo", "bar", @options)
      }.to raise_error("CondAnonymizer: Only one of default and default_strategy can be used")
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

    context "with default_strategy" do
      before(:each) do
        @options = {
          conditions: [{
            column: "bar",
            value:  "cookie",
            result: "123"
          }],
          default_strategy: :email
        }
      end

      it "uses the specified strategy if conditions are not met" do
        result = described_class.anonymize("foo", "bar", @options)
        expect(result).to eq "CASE WHEN ((foo.bar)::text = 'cookie'::text) " +
                             "THEN '123'::text " +
                             "ELSE CASE WHEN ((foo.bar)::text ~~ '%@%'::text) " +
                               "THEN (((\"left\"(md5((foo.bar)::text), 15) || '@'::text) || " +
                                 "split_part((foo.bar)::text, '@'::text, 2)))::character varying" +
                               " ELSE foo.bar END " +
                             "END"
      end

      it "raises an exception if the specified default_strategy is not implemented" do
        @options[:default_strategy] = :foobar
        expect {
          described_class.anonymize("foo", "bar", @options)
        }.to raise_error("default_strategy 'foobar' not implemented for Postgresql")
      end
    end
  end
end
