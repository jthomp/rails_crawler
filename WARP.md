# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

Rails Crawler is a Ruby gem for crawling Rails applications to detect broken pages, HTTP errors, and broken links. It's designed for CI/CD health checks and site validation. The gem provides both a command-line interface and Rake task integration for Rails applications.

## Common Development Commands

### Setup & Dependencies
```bash
# Install dependencies
bundle install

# Run initial setup script
bin/setup
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/rails_crawler/crawler_spec.rb

# Run tests with coverage
bundle exec rspec --format documentation

# Run tests matching a pattern
bundle exec rspec -e "crawl_site"
```

### Code Quality
```bash
# Run RuboCop for style checking
bundle exec rubocop

# Auto-fix RuboCop violations
bundle exec rubocop -a

# Run all default tasks (specs and rubocop)
bundle exec rake
```

### Building & Installing the Gem
```bash
# Build the gem
gem build rails_crawler.gemspec

# Install locally for testing
gem install ./rails_crawler-*.gem

# Release new version (updates version, creates git tag, pushes to RubyGems)
bundle exec rake release
```

### Testing the Crawler
```bash
# Test crawling with command line
./exe/rails_crawler http://localhost:3000

# With options
./exe/rails_crawler --format json --output report.json --concurrent 10 http://localhost:3000

# Test rake tasks (in a Rails app context)
rake crawler:crawl BASE_URL=http://localhost:3000
rake crawler:crawl_models
rake crawler:config
```

### Console Testing
```bash
# Open IRB with gem loaded
bin/console

# Test in IRB
RailsCrawler.crawl('http://example.com')
```

## Architecture & Key Components

### Core Module Structure
- **`lib/rails_crawler.rb`** - Main module entry point, handles configuration and provides the primary `crawl` method
- **`lib/rails_crawler/configuration.rb`** - Configuration class managing all crawler settings (concurrency, delays, patterns, output formats)
- **`lib/rails_crawler/crawler.rb`** - Main crawler implementation using concurrent-ruby for thread pool management and Nokogiri for HTML parsing
- **`lib/rails_crawler/report.rb`** - Report generation class supporting multiple output formats (console, JSON, CSV)
- **`lib/rails_crawler/railtie.rb`** - Rails integration providing automatic configuration and rake task loading
- **`lib/rails_crawler/version.rb`** - Version constant definition

### Rails Integration
- **`lib/rails_crawler/tasks.rake`** - Defines three rake tasks:
  - `crawler:crawl` - Full site crawl with configurable options via environment variables
  - `crawler:crawl_models` - Crawls Rails model URLs (Products, Categories) using Rails route helpers
  - `crawler:config` - Displays current configuration

### Generator
- **`lib/generators/rails_crawler/install_generator.rb`** - Rails generator for creating initializer
- **`lib/generators/rails_crawler/templates/initializer.rb`** - Template for Rails configuration file

### Key Design Patterns
1. **Concurrent Crawling**: Uses `Concurrent::FixedThreadPool` for parallel URL processing with configurable max_concurrent setting
2. **Configuration Pattern**: Singleton configuration object with chainable DSL for Rails apps
3. **Report Generation**: Strategy pattern for output formats (console/JSON/CSV)
4. **URL Queue Management**: Thread-safe Set for visited URLs and Queue for pending URLs
5. **Rails Auto-discovery**: Automatic base URL detection based on Rails environment

## Testing Approach

### Test Structure
- **`spec/rails_crawler_spec.rb`** - Module-level integration tests
- **`spec/rails_crawler/crawler_spec.rb`** - Core crawling logic and concurrency tests
- **`spec/rails_crawler/configuration_spec.rb`** - Configuration management tests
- **`spec/rails_crawler/report_spec.rb`** - Report generation and formatting tests

### Test Utilities
- Uses VCR for HTTP request recording/playback
- WebMock for stubbing external requests
- SimpleCov for code coverage reporting

## Dependencies

### Runtime Dependencies
- **colorize** (~> 0.8) - Terminal output coloring
- **concurrent-ruby** (~> 1.1) - Thread pool management for concurrent crawling
- **csv** (~> 3.3) - CSV report generation
- **nokogiri** (~> 1.13) - HTML parsing for link extraction

### Development Dependencies
- **rspec** (~> 3.0) - Testing framework
- **rubocop** (~> 1.21) - Ruby style guide enforcement
- **simplecov** (~> 0.13) - Code coverage analysis
- **vcr** (~> 6.1) - HTTP interaction recording
- **webmock** (~> 3.14) - HTTP request stubbing

## Release Process

1. Update version in `lib/rails_crawler/version.rb`
2. Update CHANGELOG.md with release notes
3. Commit changes: `git commit -am "Release version X.Y.Z"`
4. Run release task: `bundle exec rake release`
   - Creates git tag
   - Pushes to GitHub
   - Builds and pushes gem to RubyGems.org

## Environment Variables

The crawler accepts these environment variables when using rake tasks:
- `BASE_URL` - Override base URL for crawling
- `FORMAT` - Output format (console/json/csv)
- `OUTPUT_FILE` - File path for report output
- `MAX_CONCURRENT` - Number of concurrent threads
- `FOLLOW_EXTERNAL` - Whether to follow external links (true/false)

## Configuration Files

The gem supports configuration via initializer in Rails apps:
- `config/initializers/rails_crawler.rb` - Rails configuration file
- Patterns use Ruby regular expressions for URL filtering
- Supports both exclude and include patterns for fine-grained control