# frozen_string_literal: true

require_relative 'build_output_parser.rb'
require 'json'
require 'fileutils'

class Detective
  def investigate(build_parse, build_path, output_path)
    raise ArgumentError, 'Missing build to investigate' unless build_path
    raise ArgumentError, 'Missing output path' unless output_path

    full_output_path = full_path(output_path)
    latest_build_path = full_path(build_path)
    
    results = build_parser.parse_raw_from(lift_state(full_output_path), latest_build_path)
    File.write(full_output_path, results.to_json)
  end

  def report_for(report_printer, report_path)
    raw_report = File.read full_path(report_path)

    raw_report = JSON.parse(raw_report, symbolize_names: true)

    report_printer.print_from(raw_report)
  end

  def report_to(client, remote_topic_id, report_builder, report_path)
    report = report_for(report_builder, report_path)
    client.create_post(topic_id: remote_topic_id, raw: report)
  end

  private

  def full_path(relative_path)
    File.expand_path(relative_path, __FILE__)
  end

  def lift_state(state_path)
    return @parser.clean_state if File.zero?(state_path)

    raw_state = File.read(state_path)
    JSON.parse(raw_state, symbolize_names: true)
  end
end
