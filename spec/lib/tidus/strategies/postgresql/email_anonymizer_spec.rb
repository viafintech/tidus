# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::EmailAnonymizer do    
  it "returns a statement that replaces the user part of an email address" do
    result = described_class.anonymize("foo", "bar")
    result.should == "CASE WHEN ((foo.bar)::text ~~ '%@%'::text) " +
            "THEN (((\"left\"(md5((foo.bar)::text), 15) || '@'::text) " +
            "|| split_part((foo.bar)::text, '@'::text, 2)))::character varying " +
            "ELSE foo.bar END"
  end

  it "allows setting another length for the user part" do
    result = described_class.anonymize("foo", "bar", { length: 10 })
    result.should == "CASE WHEN ((foo.bar)::text ~~ '%@%'::text) " +
            "THEN (((\"left\"(md5((foo.bar)::text), 10) || '@'::text) " +
            "|| split_part((foo.bar)::text, '@'::text, 2)))::character varying " +
            "ELSE foo.bar END"
  end

  it "allows anonymizing the domain part" do
    result = described_class.anonymize("foo", "bar", { length: 10, anonymize_domain: true })
    result.should == "CASE WHEN ((foo.bar)::text ~~ '%@%'::text) " +
            "THEN (((\"left\"(md5((foo.bar)::text), 10) || '@'::text) " +
            "|| (\"left\"(md5(split_part((foo.bar)::text, '@'::text, 2)::text), 10) || '.com')" +
            ")::character varying " +
            "ELSE foo.bar END"
  end
end
