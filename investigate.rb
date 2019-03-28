# frozen_string_literal: true
#!/usr/bin/env ruby
require_relative 'lib/detective.rb'

build_path = ARGV[0]
output_path = ARGV[1]

puts build_path
puts output_path
Detective.build_detective.investigate(build_path, output_path)