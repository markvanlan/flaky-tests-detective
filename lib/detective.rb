# frozen_string_literal: true

require_relative 'build_output_parser.rb'
require 'json'
require 'fileutils'

class Detective
  def investigate(build_parse, build_path, output_path)
    full_output_path = full_path(output_path)
    latest_build_path = full_path(build_path)
    
    results = build_parser.parse_raw_from(lift_state(full_output_path), latest_build_path)
    File.write(full_output_path, results.to_json)
  end

  def report_for(report_printer, threshold, raw_report, previous_report = clean_report)
    filtered_report = raw_report.dup
    curate_report!(filtered_report, previous_report, :ruby_tests, threshold)
    curate_report!(filtered_report, previous_report, :js_tests, threshold)

    report_printer.print_from(filtered_report)
  end

  def report_to(client, remote_topic_id, report_printer, raw_report, previous_report, threshold)
    report = report_for(report_printer, threshold, raw_report, previous_report)
    client.create_post(topic_id: remote_topic_id, raw: report)
  end

  private

  def curate_report!(report, previous_report, test_key, threshold)
    report[test_key].delete_if do |test_name, test| 
      test[:failures] < threshold || 
      report.dig(test_key, test_name, :failures) == previous_report.dig(test_key, test_name, :failures)
    end
  end

  def full_path(relative_path)
    File.expand_path(relative_path, __FILE__)
  end

  def clean_report
    { metadata: { runs: 0, last_commit_hash: nil }, ruby_tests: {}, js_tests: {} }
  end

  def lift_state(state_path)
    return clean_report if File.zero?(state_path)

    raw_state = File.read(state_path)
    JSON.parse(raw_state, symbolize_names: true)
  end
end
