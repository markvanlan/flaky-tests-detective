# frozen_string_literal: true

require_relative 'build_output_parser.rb'
require 'json'

class Detective
  def self.build_detective
    new(BuildOutputParser.new)
  end

  def initialize(build_parser)
    @parser = build_parser
  end

  def investigate(build_path, output_path)
    raise ArgumentError, 'Missing build to investigate' unless build_path
    raise ArgumentError, 'Missing output path' unless output_path

    full_output_path = full_path(output_path)

    results = @parser.parse_raw_from lift_state(full_output_path), full_path(build_path)

    File.write(full_output_path, results.to_json)
  end

  def report_for(report_builder, report_path)
    raw_report = File.read full_path(report_path)

    raw_report = JSON.parse(raw_report, symbolize_names: true)

    report_builder.parse_raw_from(raw_report)
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
