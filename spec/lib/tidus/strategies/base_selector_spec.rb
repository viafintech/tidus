# encoding: utf-8

require 'spec_helper'

describe Tidus::BaseSelector do
  it "calls the corresponding base klass" do
    ActiveRecord::Base.stub_chain(:connection, :instance_values)
                      .and_return({ "config" => {
                        :adapter => "stuff"
                      } })

    Kernel.should_receive(:const_get).with("Tidus::Stuff::BaseSelector")
          .and_return(Object)
    Object.should_receive(:anonymize).with("foo", "bar", {})
    described_class.anonymize("foo", "bar")
  end

  it "raises an exception if a klass is not found for a specific adapter" do
    ActiveRecord::Base.stub_chain(:connection, :instance_values)
                      .and_return({ "config" => {
                        :adapter => "stuff"
                      } })
    expect {
      described_class.anonymize("foo", "bar")
    }.to raise_error "Tidus::BaseSelector not implemented for stuff"
  end

end