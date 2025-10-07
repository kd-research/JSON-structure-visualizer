#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

# HelpMeUnderstandJSON - A utility to visualize JSON structure in a readable format
#
# This module provides functionality to flatten nested JSON structures into
# dot-notation paths, making it easier to understand complex JSON schemas.
module HelpMeUnderstandJSON
  # Maximum length for value display before truncation
  STRUCTURE_LIMIT = 50

  module_function

  # Pretty-print JSON structure with dot-notation paths
  #
  # @param json [Object] The JSON object to process (Hash, Array, or primitive)
  # @param path [String] The current path in dot-notation (used for recursion)
  # @return [String] Formatted string representation of the JSON structure
  #
  # @example
  #   simple_json_pp({ "user" => { "name" => "John" } })
  #   # => ".user.name = \"John\"\n"
  def simple_json_pp(json, path = '')
    case json
    when Hash
      # Process each hash key-value pair recursively
      json.map do |(key, value)|
        simple_json_pp(value, "#{path}.#{key}")
      end.join
    when Array
      # Handle arrays by showing merged structure or first element
      if json.empty?
        "#{path}.[] = []\n"
      elsif json[0].is_a?(Hash)
        # Merge all hash elements to show combined structure
        simple_json_pp({}.merge(*json), "#{path}.[](merged)")
      else
        # Show first element as representative
        simple_json_pp(json[0], "#{path}.[](first)")
      end
    when nil
      # Represent null values
      "#{path} = null\n"
    else
      # Display primitive values (strings, numbers, booleans)
      data = json.inspect
      data = "#{data.slice(0, STRUCTURE_LIMIT - 3)}..." if data.length > STRUCTURE_LIMIT
      data += '"' if data.start_with?('"') && !data.end_with?('"')
      "#{path} = #{data}\n"
    end
  end
end

# CLI entry point
if $PROGRAM_NAME == __FILE__
  # Display help information
  if ARGV.include?('--help') || ARGV.include?('-h')
    puts 'Usage: ruby hmuj.rb [file.json]'
    puts 'Reads JSON from a file or standard input and pretty-prints its structure.'
    puts ''
    puts 'Examples:'
    puts '  ruby hmuj.rb data.json'
    puts '  echo \'{"key":"value"}\' | ruby hmuj.rb'
    exit
  end

  # Parse and display JSON structure
  begin
    json = JSON.parse(ARGF.read)
    puts HelpMeUnderstandJSON.simple_json_pp(json)
  rescue JSON::ParserError => e
    warn "Error parsing JSON: #{e.message}"
    exit 1
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
