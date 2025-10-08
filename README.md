# HelpMeUnderstandJSON (HMUJ)

A Ruby utility for visualizing JSON structure in a readable, dot-notation format. This tool helps developers understand complex JSON schemas by flattening nested structures into clear, hierarchical paths.

## Features

- **Dot-notation visualization**: Converts nested JSON into readable `.path.to.value` format
- **Array handling**: Intelligently merges array elements or shows representative samples
- **Path filtering**: Ignore specific paths using exact matches or glob patterns
- **Sorting**: Optional alphabetical sorting of hash keys
- **Sensitive data protection**: Hide sensitive fields with optional reason annotations
- **CLI interface**: Easy-to-use command-line tool with comprehensive options

## Usage

### Basic Usage

```bash
# Analyze a JSON file
ruby hmuj.rb data.json

# Analyze JSON from stdin
echo '{"user": {"name": "John", "age": 30}}' | ruby hmuj.rb

# Show help
ruby hmuj.rb --help
```

### Advanced Features

```bash
# Ignore sensitive paths
ruby hmuj.rb --ignore-path=.user.password data.json

# Use glob patterns to ignore multiple paths
ruby hmuj.rb --ignore-path=*.password --ignore-path=*.secret data.json

# Add reasons for ignored paths
ruby hmuj.rb --ignore-path=.user.password::"sensitive data" data.json

# Sort keys alphabetically
ruby hmuj.rb -S data.json

# Combine options
ruby hmuj.rb -S --ignore-path=*.password::"all passwords" data.json
```

## Example Output

Input JSON:
```json
{
  "user": {
    "name": "John",
    "age": 30,
    "password": "secret123"
  },
  "items": [1, 2, 3]
}
```

Output:
```
.user.name = "John"
.user.age = 30
.user.password = "secret123"
.items.[](first) = 1
```

With ignore path:
```bash
ruby hmuj.rb --ignore-path=.user.password data.json
```

Output:
```
.user.name = "John"
.user.age = 30
.user.password (ignored)
.items.[](first) = 1
```

## Development Environment

This project uses Nix for Ruby development environment management.

### Setup

```bash
# Enter development shell
nix-shell

# Install dependencies
bundle install

# Generate gemset.nix (required for nix build)
bundix -m
```

### Running Tests

```bash
# Run all tests
ruby hmuj_spec.rb

# Run specific test suites
ruby hmuj_ignore_paths_spec.rb
ruby hmuj_sort_keys_spec.rb
```

### Building

```bash
# Build the project (requires setup steps above)
nix build
```

## Project Structure

- `hmuj.rb` - Main application and HelpMeUnderstandJSON module
- `hmuj_spec.rb` - Core functionality tests
- `hmuj_ignore_paths_spec.rb` - Path filtering and glob pattern tests
- `hmuj_sort_keys_spec.rb` - Key sorting functionality tests
- `Gemfile` - Ruby dependencies
- `flake.nix` - Nix flake configuration

## Use Cases

- **API Documentation**: Understand response structures from REST APIs
- **Data Analysis**: Explore complex JSON datasets
- **Debugging**: Visualize nested configuration files
- **Schema Understanding**: Learn the structure of unfamiliar JSON formats
- **Security Auditing**: Identify sensitive fields in JSON data
