# encoding: utf-8

require 'spec_helper'

describe Tidus::RemoveJsonKeysAnonymizer do
  it "inherits from BaseSelector" do
    described_class.ancestors.include?(Tidus::BaseSelector)
  end
end
