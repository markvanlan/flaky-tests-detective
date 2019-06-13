# frozen_string_literal: true

# !/usr/bin/env ruby
require_relative 'lib/detective.rb'
require_relative 'lib/printers/text_printer.rb'

build_path = ARGV[0]

puts Detective.new.report_for(TextPrinter.new, build_path)
