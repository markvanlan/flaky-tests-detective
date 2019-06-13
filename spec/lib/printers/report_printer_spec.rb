require_relative '../../spec_helper.rb'
require_relative '../../../lib/printers/report_printer.rb'
require 'json'
require 'fileutils'
require 'date'

RSpec.describe ReportPrinter do
  let(:raw_json_path) { File.expand_path('../../examples/build_report.json', __dir__) }
  let(:json_report) { JSON.parse(File.read(raw_json_path), symbolize_names: true) }

  it 'includes the title' do
    title = "## Flakey tests report - #{Date.today.strftime('%m/%d/%Y')}"

    report = subject.print_from(json_report)

    expect(report).to include(title)
  end

  it 'includes the total runs amount' do
    runs_count = json_report.dig(:metadata, :runs)

    report = subject.print_from(json_report)

    expect(report).to include(">Total runs: #{runs_count}")
  end

  it 'includes the last commit hash' do
    last_commit = json_report.dig(:metadata, :last_commit_hash)

    report = subject.print_from(json_report)

    expect(report).to include(">Last commit: #{last_commit}")
  end

  describe 'Ruby tests' do
    it 'displays test information correctly' do
      spec_data = json_report.dig(:ruby_tests, :spec_components_cooked_post_processor_spec_rb_1291)
      test_report = <<~eos
      1. #{spec_data[:module]}
        - Failures: #{spec_data[:failures]}
        - <details>
            <summary>Show details</summary>

            - **Seed:** #{spec_data[:seed]}
            - **First seen:** #{spec_data[:appeared_on]}
            - **Last seen:** #{spec_data[:last_seen]}
            - **Assertion:** #{spec_data[:assertion]}
            - **Result:** ```#{spec_data[:result]}```
          </details>
      eos

      report = subject.print_from(json_report)

      expect(report).to include(test_report)
    end
  end

  describe 'JS tests' do
    it 'displays test information correctly' do
      key = 'test_failed_replace-text_event_cursor_behind_needle_becomes_cursor_behind_replacement'.to_sym
      spec_data = json_report.dig(:js_tests, key)
      test_report = <<~eos
      2. #{key.to_s.gsub('_', ' ')}
        - Failures: #{spec_data[:failures]}
        - #{spec_data[:module]}
        - <details>
            <summary>Show details</summary>

            - **Seed:** #{spec_data[:seed]}
            - **First seen:** #{spec_data[:appeared_on]}
            - **Last seen:** #{spec_data[:last_seen]}
            - **Assertion:** #{spec_data[:assertion]}
            - **Result:** ```#{spec_data[:result]}```
          </details>
      eos

      report = subject.print_from(json_report)

      expect(report).to include(test_report)
    end
  end
end
