#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'optparse'

# HelpMeUnderstandJSON - A utility to visualize JSON structure in a readable format
#
# This module provides functionality to flatten nested JSON structures into
# dot-notation paths, making it easier to understand complex JSON schemas.
module HelpMeUnderstandJSON
  # Maximum length for value display before truncation
  STRUCTURE_LIMIT = 50

  module_function

  # Check if a path matches any ignore pattern (exact or glob)
  #
  # @param path [String] The path to check
  # @param ignore_paths [Array<String>] Array of exact paths or glob patterns (with optional ::reason)
  # @return [Array] [matched, reason] where matched is boolean and reason is string or nil
  def path_matches_ignore?(path, ignore_paths)
    ignore_paths.each do |pattern_with_reason|
      # Split pattern and reason by ::
      pattern, reason = pattern_with_reason.split('::', 2)

      # Remove surrounding quotes from reason if present
      if reason
        reason = reason.strip
        reason = reason[1..-2] if reason.start_with?('"') && reason.end_with?('"')
      end

      # Check if path matches pattern
      matches = if pattern.include?('*')
                  # Convert glob pattern to regex
                  # Escape special regex characters except *
                  regex_pattern = Regexp.escape(pattern).gsub('\*', '.*')
                  path.match?(/^#{regex_pattern}$/)
                else
                  # Exact match
                  path == pattern
                end

      return [true, reason] if matches
    end

    [false, nil]
  end

  # Pretty-print JSON structure with dot-notation paths
  #
  # @param json [Object] The JSON object to process (Hash, Array, or primitive)
  # @param path [String] The current path in dot-notation (used for recursion)
  # @param ignore_paths [Array<String>] Paths to ignore (exact or glob patterns, with optional ::reason)
  # @return [String] Formatted string representation of the JSON structure
  #
  # @example
  #   simple_json_pp({ "user" => { "name" => "John" } })
  #   # => ".user.name = \"John\"\n"
  def simple_json_pp(json, path = '', ignore_paths = [])
    # Check if current path should be ignored
    matched, reason = path_matches_ignore?(path, ignore_paths)
    if matched
      if reason && !reason.empty?
        return "#{path} (ignored: #{reason})\n"
      else
        return "#{path} (ignored)\n"
      end
    end

    case json
    when Hash
      # Process each hash key-value pair recursively
      json.map do |(key, value)|
        simple_json_pp(value, "#{path}.#{key}", ignore_paths)
      end.join
    when Array
      # Handle arrays by showing merged structure or first element
      if json.empty?
        "#{path}.[] = []\n"
      elsif json[0].is_a?(Hash)
        # Merge all hash elements to show combined structure
        simple_json_pp({}.merge(*json), "#{path}.[](merged)", ignore_paths)
      else
        # Show first element as representative
        simple_json_pp(json[0], "#{path}.[](first)", ignore_paths)
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
  ignore_paths = []

  # Parse command-line options
  OptionParser.new do |opts|
    opts.banner = 'Usage: hmuj.rb [options] [file.json]'
    opts.separator ''
    opts.separator 'Reads JSON from a file or standard input and pretty-prints its structure.'
    opts.separator ''
    opts.separator 'Options:'

    opts.on('--ignore-path=PATH', 'Ignore a specific path (can be used multiple times)',
            'Supports glob patterns with * wildcard',
            'Optional reason: --ignore-path=PATH::"reason"') do |path|
      ignore_paths << path
    end

    opts.on('-h', '--help', 'Show this help message') do
      puts opts
      puts ''
      puts 'Examples:'
      puts '  hmuj.rb data.json'
      puts '  echo \'{"key":"value"}\' | hmuj.rb'
      puts '  hmuj.rb --ignore-path=.user.password --ignore-path=.secret data.json'
      puts '  hmuj.rb --ignore-path=.user.password::"sensitive data" data.json'
      puts '  hmuj.rb --ignore-path=.*.secret::"all secrets" data.json'
      exit
    end
  end.parse!

  # Parse and display JSON structure
  begin
    json = JSON.parse(ARGF.read)
    puts HelpMeUnderstandJSON.simple_json_pp(json, '', ignore_paths)
  rescue JSON::ParserError => e
    warn "Error parsing JSON: #{e.message}"
    exit 1
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end
