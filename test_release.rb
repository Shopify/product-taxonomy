#!/usr/bin/env ruby

# Add the lib directory to the load path
$LOAD_PATH.unshift(File.expand_path('dev/lib', __dir__))

require 'product_taxonomy'
require 'product_taxonomy/commands/generate_release_command'

# Mock version for testing
current_version = "2025-03"
next_version = "2025-08-unstable"

puts "Running release command for testing..."
puts "Current version: #{current_version}"
puts "Next version: #{next_version}"

begin
  command = ProductTaxonomy::GenerateReleaseCommand.new(
    current_version: current_version,
    next_version: next_version,
    locales: ["en"]
  )
  command.execute
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace
end