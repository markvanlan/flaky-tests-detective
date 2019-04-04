# frozen_string_literal: true

# !/usr/bin/env ruby
require_relative 'lib/detective.rb'
require_relative 'lib/build_report_parser.rb'

build_path = ARGV[0]

puts Detective.build_detective.report_for(BuildReportParser.new, build_path)
