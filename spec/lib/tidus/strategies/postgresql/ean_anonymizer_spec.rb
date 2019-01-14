# encoding: utf-8

require 'spec_helper'

describe Tidus::Postgresql::EanAnonymizer do
  let(:table_name)  { 'table' }
  let(:column_name) { 'ean' }
  let(:start)  { 3 }
  let(:length) { 7 }
  let(:cache_key) { 'ean_mapping' }

  let(:options) do
    {
      start:     start,
      length:    length,
      cache_key: cache_key
    }
  end

  describe '.anonymize' do
    let(:start)  { nil }
    let(:length) { nil }

    let(:mapping) do
      {
        base:        '0123456789',
        replacement: '5678901234'
      }
    end

    before do
      allow(described_class)
        .to receive(:retrieve_mapping)
        .with(cache_key)
        .and_return(mapping)
    end

    it 'builds the query snippet' do
      expectation = <<-SQL
          (
            SELECT
              string_agg(new_digits.digit::TEXT, ''::TEXT)
            FROM (
              (
                SELECT
                  pos,
                  digit
                FROM (
                  SELECT
                    *
                  FROM (
                    SELECT
                      ROW_NUMBER() over () AS pos,
                      digit::INT
                    FROM (
                      SELECT
                        REGEXP_SPLIT_TO_TABLE(
                          TRANSLATE(
                            SUBSTRING(ean::TEXT, 1, LENGTH(ean::TEXT) - 1),
                            '0123456789',
                            '5678901234'
                          ),
                          ''
                        ) AS digit
                    ) AS sub
                  ) AS sub
                  WHERE pos < LENGTH(ean::TEXT)
                ) AS where_sub
                ORDER BY pos ASC
              )
              UNION ALL
              (
                SELECT
                  LENGTH(ean::TEXT) AS pos,
                  (
                    10
                    -
                    (
                      (
                        SELECT
                          SUM(digit)
                        FROM (
                          SELECT
                            *
                          FROM (
                            SELECT
                              ROW_NUMBER() over () AS pos,
                              digit::INT
                            FROM (
                              SELECT
                                REGEXP_SPLIT_TO_TABLE(
                                  TRANSLATE(
                                    SUBSTRING(ean::TEXT, 1, LENGTH(ean::TEXT) - 1),
                                    '0123456789',
                                    '5678901234'
                                  ),
                                  ''
                                ) AS digit
                            ) AS sub
                          ) AS sub
                          WHERE pos < LENGTH(ean::TEXT)
                        ) AS where_sub
                        WHERE pos % 2 = LENGTH(ean::TEXT) % 2
                      )
                      +
                      (
                        SELECT
                          SUM(digit)
                        FROM (
                          SELECT
                            *
                          FROM (
                            SELECT
                              ROW_NUMBER() over () AS pos,
                              digit::INT
                            FROM (
                              SELECT
                                REGEXP_SPLIT_TO_TABLE(
                                  TRANSLATE(
                                    SUBSTRING(ean::TEXT, 1, LENGTH(ean::TEXT) - 1),
                                    '0123456789',
                                    '5678901234'
                                  ),
                                  ''
                                ) AS digit
                            ) AS sub
                          ) AS sub
                          WHERE pos < LENGTH(ean::TEXT)
                        ) AS where_sub
                        WHERE pos % 2 = (LENGTH(ean::TEXT) - 1) % 2
                      ) * 3
                    ) % 10
                  ) % 10 AS digit
                )
              ) new_digits
            )
      SQL

      expect(described_class.anonymize(table_name, column_name, options))
        .to eq(expectation.gsub!(/\n/, '').gsub!(/\ +/, ' '))
    end
  end

  describe '.retrieve_mapping' do
    let(:retrieve_mapping_call) do
      described_class.retrieve_mapping(cache_key)
    end

    before do
      described_class.instance_variable_set("@cached_mapping", nil)
    end

    context 'when no cache_key is given' do
      let(:cache_key) { nil }

      it 'builds a new mapping' do
        mapping = described_class.retrieve_mapping(cache_key)

        expect(mapping[:base]).to eq(described_class::BASE_MAPPING)
        expect(mapping[:replacement].class).to eq(String)

        mapping2 = described_class.retrieve_mapping(cache_key)

        expect(mapping).to_not eq(mapping2)
      end
    end

    context 'when a cache_key is given' do
      it 'builds a new mapping and re-uses it on the second time' do
        mapping = described_class.retrieve_mapping(cache_key)

        expect(mapping[:base]).to eq(described_class::BASE_MAPPING)
        expect(mapping[:replacement].class).to eq(String)

        mapping2 = described_class.retrieve_mapping(cache_key)

        expect(mapping).to eq(mapping2)
      end
    end
  end

  describe '.build_mapped_digit_snippet' do
    let(:mapping) do
      {
        base:        '0123456789',
        replacement: '5678901234'
      }
    end

    before do
      allow(described_class)
        .to receive(:retrieve_mapping)
        .with(cache_key)
        .and_return(mapping)
    end

    let(:build_mapped_digit_snippet_call) do
      described_class.build_mapped_digit_snippet(column_name, options)
    end

    let(:length) { nil }

    it 'builds the barcode with individually mapped digits' do
      expect(build_mapped_digit_snippet_call)
        .to eq(
          <<-SQL
          SELECT
            *
          FROM (
            SELECT
              ROW_NUMBER() over () AS pos,
              digit::INT
            FROM (
              SELECT
                REGEXP_SPLIT_TO_TABLE(
                  SUBSTRING(ean::TEXT, 1, 2) ||  TRANSLATE( SUBSTRING(ean::TEXT, 3, LENGTH(ean::TEXT) - 1), '0123456789', '5678901234' ),
                  ''
                ) AS digit
            ) AS sub
          ) AS sub
          WHERE pos < LENGTH(ean::TEXT)
          SQL
        )
    end
  end

  describe '.build_digit_mapping' do
    let(:mapping) do
      {
        base:        '0123456789',
        replacement: '5678901234'
      }
    end

    before do
      allow(described_class)
        .to receive(:retrieve_mapping)
        .with(cache_key)
        .and_return(mapping)
    end

    let(:build_digit_mapping_call) do
      described_class.build_digit_mapping(column_name, options)
    end

    context 'when no start or length is defined' do
      let(:start)  { nil }
      let(:length) { nil }

      it 'builds only the translate part' do
        expect(build_digit_mapping_call)
          .to eq(
            [
              " TRANSLATE( SUBSTRING(ean::TEXT, 1, LENGTH(ean::TEXT) - 1), '0123456789', '5678901234' )",
            ]
          )
      end
    end

    context 'when start is defined' do
      let(:length) { nil }

      it 'builds the start substring and translate part' do
        expect(build_digit_mapping_call)
          .to eq(
            [
              "SUBSTRING(ean::TEXT, 1, 2)",
              " TRANSLATE( SUBSTRING(ean::TEXT, 3, LENGTH(ean::TEXT) - 1), '0123456789', '5678901234' )"
            ]
          )
      end
    end

    context 'when length is defined' do
      let(:start)  { nil }

      it 'translate and end substring part' do
        expect(build_digit_mapping_call)
          .to eq(
            [
              " TRANSLATE( SUBSTRING(ean::TEXT, 1, 7), '0123456789', '5678901234' )",
              'SUBSTRING(ean::TEXT, 1 + 7, LENGTH(ean::TEXT) - 1 - 1)'
            ]
          )
      end
    end

    context 'when start and length are defined' do
      it 'builds start, translate, and end parts' do
        expect(build_digit_mapping_call)
          .to eq(
            [
              'SUBSTRING(ean::TEXT, 1, 2)',
              " TRANSLATE( SUBSTRING(ean::TEXT, 3, 7), '0123456789', '5678901234' )",
              'SUBSTRING(ean::TEXT, 3 + 7, LENGTH(ean::TEXT) - 1 - 3)'
            ]
          )
      end
    end
  end

  describe '.build_substring_snippet' do
    let(:build_substring_snippet_call) do
      described_class.build_substring_snippet(column_name, start, length)
    end

    it 'builds a SUBTRING snippet' do
      expect(build_substring_snippet_call)
        .to eq('SUBSTRING(ean::TEXT, 3, 7)')
    end
  end
end
