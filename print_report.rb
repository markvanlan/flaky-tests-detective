# frozen_string_literal: true

# !/usr/bin/env ruby
require_relative 'lib/detective.rb'
require_relative 'lib/printers/text_printer.rb'

report_path = ARGV[0]
raw_report = File.read(File.expand_path(report_path, __FILE__))
raw_report = JSON.parse(raw_report, symbolize_names: true)
threshold = 3

puts Detective.new.report_for(TextPrinter.new, raw_report, threshold)
