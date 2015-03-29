# encoding: utf-8

require 'spec_helper'

describe Tidus::TextAnonymizer do
  it "inherits from BaseSelector" do
    described_class.ancestors.include?(Tidus::BaseSelector)
  end
end