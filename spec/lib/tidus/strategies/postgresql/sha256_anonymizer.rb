# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::Sha256Anonymizer do
  context 'when length is not given' do
    it 'defaults to 64 (+1)' do
      expect(described_class.anonymize("foo", "bar"))
        .to eq("SUBSTR(ENCODE(DIGEST(foo.bar, 'sha256')::TEXT, 'HEX'), 0, 65)")
    end
  end

  context 'when length is given' do
    it 'uses the given length' do
      expect(described_class.anonymize("foo", "bar", length: 10))
        .to eq("SUBSTR(ENCODE(DIGEST(foo.bar, 'sha256')::TEXT, 'HEX'), 0, 11)")
    end
  end
end
