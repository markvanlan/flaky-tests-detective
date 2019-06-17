# frozen_string_literal: true

# !/usr/bin/env ruby
require_relative 'lib/detective.rb'
require_relative 'lib/printers/text_printer.rb'
require_relative 'lib/archives/file_system_archive.rb'

report_path = ARGV[0]
report_filename = ARGV[1]
threshold = 3

working_dir = File.expand_path('../reports', __FILE__)
archive = FileSystemArchive.new(working_dir, report_filename)

puts Detective.new.report_for(TextPrinter.new, threshold, archive)
