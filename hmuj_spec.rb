#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'hmuj'

# Test suite for HelpMeUnderstandJSON module
class HelpMeUnderstandJSONTest < Minitest::Test
  def test_simple_hash
    input = { 'name' => 'John' }
    expected = ".name = \"John\"\n"
    assert_equal expected, HelpMeUnderstandJSON.simple_json_pp(input)
  end

  def test_nested_hash
    input = { 'user' => { 'name' => 'John', 'age' => 30 } }
    output = HelpMeUnderstandJSON.simple_json_pp(input)
    assert_includes output, '.user.name = "John"'
    assert_includes output, '.user.age = 30'
  end

  def test_array_of_primitives
    input = { 'numbers' => [1, 2, 3] }
    expected = ".numbers.[](first) = 1\n"
    assert_equal expected, HelpMeUnderstandJSON.simple_json_pp(input)
  end

  def test_array_of_hashes
    input = {
      'users' => [
        { 'name' => 'John', 'age' => 30 },
        { 'name' => 'Jane', 'age' => 25 }
      ]
    }
    output = HelpMeUnderstandJSON.simple_json_pp(input)
    assert_includes output, '.users.[](merged).name = "Jane"'
    assert_includes output, '.users.[](merged).age = 25'
  end

  def test_empty_array
    input = { 'items' => [] }
    expected = ".items.[] = []\n"
    assert_equal expected, HelpMeUnderstandJSON.simple_json_pp(input)
  end

  def test_null_value
    input = { 'value' => nil }
    expected = ".value = null\n"
    assert_equal expected, HelpMeUnderstandJSON.simple_json_pp(input)
  end

  def test_boolean_values
    input = { 'active' => true, 'deleted' => false }
    output = HelpMeUnderstandJSON.simple_json_pp(input)
    assert_includes output, '.active = true'
    assert_includes output, '.deleted = false'
  end

  def test_number_values
    input = { 'integer' => 42, 'float' => 3.14 }
    output = HelpMeUnderstandJSON.simple_json_pp(input)
    assert_includes output, '.integer = 42'
    assert_includes output, '.float = 3.14'
  end

  def test_long_string_truncation
    long_string = 'a' * 100
    input = { 'text' => long_string }
    output = HelpMeUnderstandJSON.simple_json_pp(input)
    assert_includes output, '...'
    # Should be truncated to STRUCTURE_LIMIT (50) - 3 for "..." + 2 for quotes = 47 chars + "..."
    assert output.length < long_string.length
  end

  def test_deeply_nested_structure
    input = {
      'level1' => {
        'level2' => {
          'level3' => {
            'value' => 'deep'
          }
        }
      }
    }
    expected = ".level1.level2.level3.value = \"deep\"\n"
    assert_equal expected, HelpMeUnderstandJSON.simple_json_pp(input)
  end

  def test_complex_real_world_example
    input = {
      'name' => 'Bramble Rootwhisper',
      'age' => 'Young Ent',
      'skills' => ['Gardening', 'Plant growth'],
      'personality' => {
        'traits' => ['Gentle', 'Wise'],
        'fears' => ['Disappointing family']
      }
    }
    output = HelpMeUnderstandJSON.simple_json_pp(input)

    assert_includes output, '.name = "Bramble Rootwhisper"'
    assert_includes output, '.age = "Young Ent"'
    assert_includes output, '.skills.[](first) = "Gardening"'
    assert_includes output, '.personality.traits.[](first) = "Gentle"'
    assert_includes output, '.personality.fears.[](first) = "Disappointing family"'
  end

  def test_empty_hash
    input = {}
    expected = ''
    assert_equal expected, HelpMeUnderstandJSON.simple_json_pp(input)
  end

  def test_mixed_types_in_nested_structure
    input = {
      'data' => {
        'count' => 5,
        'active' => true,
        'message' => nil,
        'items' => [1, 2, 3]
      }
    }
    output = HelpMeUnderstandJSON.simple_json_pp(input)

    assert_includes output, '.data.count = 5'
    assert_includes output, '.data.active = true'
    assert_includes output, '.data.message = null'
    assert_includes output, '.data.items.[](first) = 1'
  end
end
