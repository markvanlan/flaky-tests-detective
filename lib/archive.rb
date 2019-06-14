# frozen_string_literal: true

require 'json'
require 'fileutils'

class Archive
  def initialize(working_dir, last_build_file_name)
    @working_dir = working_dir
    @last_build_file_name = last_build_file_name
  end

  def tests_report
    find_report(tests_report_path)
  end

  def store_tests_report(report)
    File.write(tests_report_path, report.to_json)
  end

  def destroy_tests_report
    FileUtils.rm(tests_report_path) if File.exist?(tests_report_path)
  end

  def last_report_sent
    find_report(last_report_path)
  end

  def update_last_report_sent(report)
    File.write(last_report_path, report.to_json)
  end

  def clean_report
    { metadata: { runs: 0, last_commit_hash: nil }, ruby_tests: {}, js_tests: {} }
  end

  def raw_build_iterator
    File.foreach(full_path("#{@working_dir}/#{@last_build_file_name}"))
  end

  private

  def last_report_path
    full_path("#{@working_dir}/last_report_sent.json")
  end

  def tests_report_path
    full_path("#{@working_dir}/build_report.json")
  end

  def full_path(relative)
    File.expand_path(relative, __FILE__)
  end

  def find_report(report_name)
    path = full_path(report_name)
    return clean_report unless File.exist?(path)

    raw_report = File.read(path)

    JSON.parse(raw_report, symbolize_names: true)
  end
end
