#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'hmuj'

# Test suite for ignore_paths functionality
class HelpMeUnderstandJSONIgnorePathsTest < Minitest::Test
  # ===== Exact Match Tests =====

  def test_single_ignore_path_on_primitive_value
    input = { 'user' => { 'name' => 'John', 'password' => 'secret123' } }
    ignore_paths = ['.user.password']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.user.name = "John"'
    refute_includes output, 'secret123'
  end

  def test_single_ignore_path_on_nested_object
    input = {
      'user' => {
        'name' => 'John',
        'address' => {
          'street' => '123 Main St',
          'city' => 'Boston'
        }
      }
    }
    ignore_paths = ['.user.address']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.address (ignored)'
    assert_includes output, '.user.name = "John"'
    refute_includes output, '.user.address.street'
    refute_includes output, '123 Main St'
  end

  def test_multiple_ignore_paths
    input = {
      'user' => { 'password' => 'secret123' },
      'api' => { 'secret' => 'apikey456' },
      'public' => { 'name' => 'App' }
    }
    ignore_paths = ['.user.password', '.api.secret']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.api.secret (ignored)'
    assert_includes output, '.public.name = "App"'
    refute_includes output, 'secret123'
    refute_includes output, 'apikey456'
  end

  def test_ignore_path_doesnt_affect_siblings
    input = {
      'user' => {
        'name' => 'John',
        'email' => 'john@example.com',
        'password' => 'secret123'
      }
    }
    ignore_paths = ['.user.password']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.user.name = "John"'
    assert_includes output, '.user.email = "john@example.com"'
  end

  def test_ignore_path_with_array_elements
    input = {
      'users' => [
        { 'name' => 'John', 'password' => 'secret123' },
        { 'name' => 'Jane', 'password' => 'secret456' }
      ]
    }
    ignore_paths = ['.users.[](merged).password']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.users.[](merged).password (ignored)'
    assert_includes output, '.users.[](merged).name = "Jane"'
    refute_includes output, 'secret123'
    refute_includes output, 'secret456'
  end

  def test_ignore_path_that_doesnt_exist
    input = { 'user' => { 'name' => 'John' } }
    ignore_paths = ['.user.nonexistent', '.api.secret']

    # Should not raise error
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.name = "John"'
    refute_includes output, '(ignored)'
  end

  def test_empty_ignore_paths_array
    input = { 'user' => { 'name' => 'John', 'password' => 'secret123' } }
    ignore_paths = []
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    # Should behave like original (show everything)
    assert_includes output, '.user.name = "John"'
    assert_includes output, '.user.password = "secret123"'
    refute_includes output, '(ignored)'
  end

  # ===== Glob Pattern Tests =====

  def test_glob_wildcard_at_end
    input = {
      'user' => {
        'password' => 'secret123',
        'email' => 'john@example.com',
        'token' => 'abc123'
      },
      'admin' => { 'name' => 'Admin' }
    }
    ignore_paths = ['.user.*']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.user.email (ignored)'
    assert_includes output, '.user.token (ignored)'
    assert_includes output, '.admin.name = "Admin"'
  end

  def test_glob_wildcard_at_beginning
    input = {
      'user' => { 'password' => 'secret123' },
      'admin' => { 'password' => 'admin456' },
      'public' => { 'name' => 'App' }
    }
    ignore_paths = ['*.password']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.admin.password (ignored)'
    assert_includes output, '.public.name = "App"'
  end

  def test_glob_wildcard_in_middle
    input = {
      'data' => {
        'api' => { 'config' => 'value1' },
        'db' => { 'config' => 'value2' },
        'cache' => { 'config' => 'value3' },
        'other' => { 'setting' => 'value4' }
      }
    }
    ignore_paths = ['.data.*.config']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.data.api.config (ignored)'
    assert_includes output, '.data.db.config (ignored)'
    assert_includes output, '.data.cache.config (ignored)'
    assert_includes output, '.data.other.setting = "value4"'
  end

  def test_glob_wildcard_for_any_substring
    input = {
      'user' => { 'secret' => 'val1' },
      'mysecret' => { 'value' => 'val2' },
      'data' => { 'topsecret' => 'val3' },
      'public' => { 'name' => 'App' }
    }
    ignore_paths = ['*secret*']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.secret (ignored)'
    assert_includes output, '.mysecret (ignored)'  # Matches at parent level, stops recursion
    assert_includes output, '.data.topsecret (ignored)'
    assert_includes output, '.public.name = "App"'
  end

  def test_glob_multiple_wildcards
    input = {
      'user' => { 'profile' => { 'id' => 1 } },
      'admin' => { 'account' => { 'id' => 2 } },
      'data' => { 'value' => 'test' }
    }
    ignore_paths = ['*.*.id']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.profile.id (ignored)'
    assert_includes output, '.admin.account.id (ignored)'
    assert_includes output, '.data.value = "test"'
  end

  def test_glob_with_array_notation
    input = {
      'users' => [
        { 'name' => 'John', 'password' => 'secret123', 'id' => 1 },
        { 'name' => 'Jane', 'password' => 'secret456', 'id' => 2 }
      ]
    }
    ignore_paths = ['.users.[](merged).*']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.users.[](merged).name (ignored)'
    assert_includes output, '.users.[](merged).password (ignored)'
    assert_includes output, '.users.[](merged).id (ignored)'
  end

  def test_glob_pattern_that_matches_nothing
    input = { 'user' => { 'name' => 'John' } }
    ignore_paths = ['*.nonexistent']

    # Should not raise error
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.name = "John"'
    refute_includes output, '(ignored)'
  end

  def test_mixing_exact_and_glob_patterns
    input = {
      'user' => { 'password' => 'secret123', 'email' => 'john@example.com' },
      'api' => { 'key' => 'apikey', 'secret' => 'apisecret' },
      'public' => { 'name' => 'App' }
    }
    ignore_paths = ['.user.password', '.api.*']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    # Exact match
    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.user.email = "john@example.com"'

    # Glob match
    assert_includes output, '.api.key (ignored)'
    assert_includes output, '.api.secret (ignored)'

    # Unaffected
    assert_includes output, '.public.name = "App"'
  end

  def test_glob_doesnt_prevent_siblings
    input = {
      'user' => {
        'password' => 'secret123',
        'passcode' => '999',
        'email' => 'john@example.com'
      }
    }
    ignore_paths = ['.user.pass*']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored)'
    assert_includes output, '.user.passcode (ignored)'
    assert_includes output, '.user.email = "john@example.com"'
  end

  # ===== Ignore Path with Reasons Tests =====

  def test_exact_match_with_reason
    input = { 'user' => { 'password' => 'secret123', 'email' => 'john@example.com' } }
    ignore_paths = ['.user.password::"sensitive data"']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored: sensitive data)'
    assert_includes output, '.user.email = "john@example.com"'
    refute_includes output, 'secret123'
  end

  def test_glob_pattern_with_reason
    input = {
      'user' => { 'password' => 'secret123' },
      'admin' => { 'password' => 'admin456' },
      'public' => { 'name' => 'App' }
    }
    ignore_paths = ['.*.password::"all passwords are sensitive"']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored: all passwords are sensitive)'
    assert_includes output, '.admin.password (ignored: all passwords are sensitive)'
    assert_includes output, '.public.name = "App"'
  end

  def test_multiple_ignore_paths_with_mixed_reasons
    input = {
      'user' => { 'password' => 'secret123', 'email' => 'john@example.com' },
      'public' => { 'name' => 'App' },
      'api' => { 'key' => 'apikey' }
    }
    ignore_paths = ['.user.password::"credential"', '.public.name']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.user.password (ignored: credential)'
    assert_includes output, '.public.name (ignored)'
    assert_includes output, '.user.email = "john@example.com"'
    assert_includes output, '.api.key = "apikey"'
  end

  def test_reason_with_special_characters
    input = { 'api' => { 'key' => 'secret', 'endpoint' => 'https://api.example.com' } }
    ignore_paths = ['.api.key::"API key - don\'t expose!"']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.api.key (ignored: API key - don\'t expose!)'
    assert_includes output, '.api.endpoint = "https://api.example.com"'
  end

  def test_empty_reason
    input = { 'path' => { 'value' => 'test' }, 'other' => 'data' }
    ignore_paths = ['.path::""']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    # Empty reason should behave like no reason
    assert_includes output, '.path (ignored)'
    assert_includes output, '.other = "data"'
  end

  def test_reason_with_double_colons_in_text
    input = { 'config' => { 'format' => 'key:value' }, 'other' => 'data' }
    ignore_paths = ['.config::"format: key::value"']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    assert_includes output, '.config (ignored: format: key::value)'
    assert_includes output, '.other = "data"'
  end

  def test_whitespace_handling_in_reason
    input = { 'path' => { 'value' => 'test' }, 'other' => 'data' }
    ignore_paths = ['.path::"  extra spaces  "']
    output = HelpMeUnderstandJSON.simple_json_pp(input, '', ignore_paths)

    # Preserve whitespace exactly as user provided
    assert_includes output, '.path (ignored:   extra spaces  )'
    assert_includes output, '.other = "data"'
  end
end
