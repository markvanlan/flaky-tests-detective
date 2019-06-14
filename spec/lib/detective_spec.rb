require_relative '../spec_helper.rb'
require_relative '../../lib/detective.rb'

RSpec.describe Detective do
  let(:detective) { described_class.new }

  describe '#investigate' do
    let(:raw_path) { '../report.json' }

    describe 'Validations' do
      it 'Validates that build path is included' do
        expect { detective.investigate(nil, nil, raw_path) }.to raise_error ArgumentError, 'Missing build to investigate'
      end

      it 'Validates that output path is included' do
        expect { detective.investigate(nil, raw_path, nil) }.to raise_error ArgumentError, 'Missing output path'
      end
    end
  end

  describe '#report_for' do
    let(:raw_report) do
      {
        ruby_tests: { test_ruby_a: { failures: 1 }, test_ruby_b: { failures: 2 } },
        js_tests: { test_js_a: { failures: 6 }, test_js_b: { failures: 3 } }
      }
    end

    it 'filters tests with less than one failures' do
      threshold = 1

      report = build_report(threshold)

      expect(selected_tests(report)).to contain_exactly(:test_ruby_a, :test_ruby_b, :test_js_a, :test_js_b)
    end

    it 'filters tests with less than two failures' do
      threshold = 2

      report = build_report(threshold)

      expect(selected_tests(report)).to contain_exactly(:test_ruby_b, :test_js_a, :test_js_b)
    end

    it 'filters tests with less than five failures' do
      threshold = 5

      report = build_report(threshold)

      expect(selected_tests(report)).to contain_exactly(:test_js_a)
    end

    def build_report(threshold)
      subject.report_for(NoopPrinter.new, raw_report, threshold)
    end

    def selected_tests(report)
      report[:ruby_tests].keys + report[:js_tests].keys
    end
  end

  class NoopPrinter
    def print_from(report)
      report
    end
  end
end
