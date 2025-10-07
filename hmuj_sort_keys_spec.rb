#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'hmuj'

# Test suite for --sort-keys functionality
class HelpMeUnderstandJSONSortKeysTest < Minitest::Test
  def test_basic_hash_keys_sorted
    input = { 'z' => 1, 'a' => 2, 'm' => 3 }
    output_sorted = HelpMeUnderstandJSON.simple_json_pp(input, '', [], true)
    output_unsorted = HelpMeUnderstandJSON.simple_json_pp(input, '', [], false)

    # With sorting: should appear in alphabetical order
    lines_sorted = output_sorted.split("\n")
    assert_equal '.a = 2', lines_sorted[0]
    assert_equal '.m = 3', lines_sorted[1]
    assert_equal '.z = 1', lines_sorted[2]

    # Without sorting: should maintain insertion order
    lines_unsorted = output_unsorted.split("\n")
    assert_equal '.z = 1', lines_unsorted[0]
    assert_equal '.a = 2', lines_unsorted[1]
    assert_equal '.m = 3', lines_unsorted[2]
  end

  def test_nested_hash_keys_sorted
    input = {
      'zebra' => {
        'yellow' => 1,
        'alpha' => 2
      },
      'apple' => {
        'zulu' => 3,
        'bravo' => 4
      }
    }
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', [], true)

    lines = output.split("\n")
    # Top level should be sorted: apple, zebra
    # Nested level should also be sorted
    assert_equal '.apple.bravo = 4', lines[0]
    assert_equal '.apple.zulu = 3', lines[1]
    assert_equal '.zebra.alpha = 2', lines[2]
    assert_equal '.zebra.yellow = 1', lines[3]
  end

  def test_empty_hash_with_sort_flag
    input = {}
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', [], true)

    # Empty hash should produce empty output
    assert_equal '', output
  end

  def test_array_of_hashes_merged_with_sorted_keys
    input = {
      'users' => [
        { 'z_field' => 1, 'a_field' => 2 },
        { 'b_field' => 3 }
      ]
    }
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', [], true)

    # Merged hash keys should be sorted
    lines = output.split("\n")
    assert_equal '.users.[](merged).a_field = 2', lines[0]
    assert_equal '.users.[](merged).b_field = 3', lines[1]
    assert_equal '.users.[](merged).z_field = 1', lines[2]
  end

  def test_default_behavior_without_flag
    input = { 'z' => 1, 'a' => 2, 'm' => 3 }

    # Test with explicit false
    output_false = HelpMeUnderstandJSON.simple_json_pp(input, '', [], false)
    lines_false = output_false.split("\n")
    assert_equal '.z = 1', lines_false[0]
    assert_equal '.a = 2', lines_false[1]
    assert_equal '.m = 3', lines_false[2]

    # Test with default (no sort_keys parameter)
    output_default = HelpMeUnderstandJSON.simple_json_pp(input, '', [])
    lines_default = output_default.split("\n")
    assert_equal '.z = 1', lines_default[0]
    assert_equal '.a = 2', lines_default[1]
    assert_equal '.m = 3', lines_default[2]
  end
end
