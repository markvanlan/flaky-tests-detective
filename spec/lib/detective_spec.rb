require_relative '../spec_helper.rb'
require_relative '../../lib/detective.rb'

RSpec.describe Detective do
  describe '#report_for' do
    let(:raw_report) do
      {
        ruby_tests: { test_ruby_a: { failures: 1 }, test_ruby_b: { failures: 2 } },
        js_tests: { test_js_a: { failures: 6 }, test_js_b: { failures: 3 } }
      }
    end

    let(:archive) { MemoryArchive.new(raw_report, { ruby_tests: {}, js_tests: {}}) }

    it 'filters tests with less than one failures' do
      threshold = 1

      report = build_report(threshold, archive)

      expect(selected_tests(report)).to contain_exactly(:test_ruby_a, :test_ruby_b, :test_js_a, :test_js_b)
    end

    it 'filters tests with less than two failures' do
      threshold = 2

      report = build_report(threshold, archive)

      expect(selected_tests(report)).to contain_exactly(:test_ruby_b, :test_js_a, :test_js_b)
    end

    it 'filters tests with less than five failures' do
      threshold = 5

      report = build_report(threshold, archive)

      expect(selected_tests(report)).to contain_exactly(:test_js_a)
    end

    describe 'When we are building a subsequent report' do
      let(:previous_report) do
        {
          ruby_tests: { test_ruby_a: { failures: 1 }, test_ruby_b: { failures: 1 } },
          js_tests: { test_js_a: { failures: 6 }, test_js_b: { failures: 2 } }
        }
      end

      let(:archive) { MemoryArchive.new(raw_report, previous_report) }
    
      it 'returns the test that changed since the last report' do
        threshold = 2

        report = build_report(threshold, archive)

        expect(selected_tests(report)).to contain_exactly(:test_ruby_b, :test_js_b)
      end

      it 'takes the threshold into account' do
        threshold = 5

        report = build_report(threshold, archive)

        expect(selected_tests(report)).to be_empty
      end
    end
    
    def build_report(threshold, archive)
      subject.report_for(NoopPrinter.new, threshold, archive)
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

  class MemoryArchive
    def initialize(report, last_report_sent)
      @tests_report = report
      @last_report_sent = last_report_sent
    end

    attr_reader :tests_report, :last_report_sent
  end
end
