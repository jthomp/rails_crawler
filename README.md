# RailsCrawler

A Ruby gem for crawling Rails applications to detect broken pages, HTTP errors, and broken links. Perfect for CI/CD health checks and ensuring your site's links work correctly.

## Features

- 🚀 **Fast concurrent crawling** with configurable thread pools
- 🔍 **Comprehensive link checking** - finds broken internal and external links
- 🎯 **Rails-aware** - automatically discovers routes from your Rails models
- 📊 **Multiple output formats** - console, JSON, and CSV reports
- 🛠️ **Highly configurable** - exclude patterns, concurrent limits, delays, and more
- 🧪 **CI/CD friendly** - exit codes and structured output for automation
- 📈 **Progress tracking** - real-time progress bars and colored output

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_crawler'
```

And then execute:

```bash
bundle install
```

Generate the configuration file:

```bash
rails generate rails_crawler:install
```

## Usage

### Rake Tasks (Recommended for Rails apps)

```bash
# Crawl your entire site
rake crawler:crawl

# Crawl only Rails model URLs (products, categories, etc.)
rake crawler:crawl_models

# Show current configuration
rake crawler:config
```

### Environment Variables

```bash
# Specify base URL
BASE_URL=http://localhost:3000 rake crawler:crawl

# Generate JSON report
FORMAT=json OUTPUT_FILE=report.json rake crawler:crawl

# Increase concurrency
MAX_CONCURRENT=10 rake crawler:crawl

# Follow external links
FOLLOW_EXTERNAL=true rake crawler:crawl
```

### Command Line

```bash
# Basic usage
rails_crawler http://localhost:3000

# With options
rails_crawler --format json --output report.json --concurrent 10 http://localhost:3000

# Verbose output
rails_crawler --verbose http://localhost:3000
```

### Ruby API

```ruby
# Simple crawl
report = RailsCrawler.crawl('http://localhost:3000')

# With options
report = RailsCrawler.crawl('http://localhost:3000', {
  max_concurrent: 10,
  output_format: :json,
  output_file: 'report.json'
})

# Check if healthy
puts "Site is healthy!" if report.healthy?

# Access results
puts "Checked #{report.visited_urls.length} pages"
puts "Found #{report.failed_pages.length} broken pages"
puts "Found #{report.broken_links.length} broken links"
```

## Configuration

Create `config/initializers/rails_crawler.rb`:

```ruby
RailsCrawler.configure do |config|
  config.base_url = 'http://localhost:3000'
  config.max_concurrent = 5
  config.delay_between_requests = 0.1
  config.follow_external_links = false
  config.timeout = 30
  
  # Exclude certain URLs
  config.exclude_patterns = [
    /\.(pdf|zip|tar|gz|jpg|jpeg|png|gif|svg|ico)$/i,
    /\/admin/,
    /\/api/
  ]
  
  config.output_format = :console
end
```

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `base_url` | Base URL to crawl | `nil` (required) |
| `max_concurrent` | Maximum concurrent requests | `5` |
| `delay_between_requests` | Delay between requests (seconds) | `0.1` |
| `follow_external_links` | Follow links to external domains | `false` |
| `user_agent` | HTTP User-Agent header | `RailsCrawler/VERSION` |
| `timeout` | Request timeout (seconds) | `30` |
| `exclude_patterns` | Array of regex patterns to exclude | File extensions |
| `include_patterns` | Array of regex patterns to include | `[]` (all) |
| `output_format` | Output format (`:console`, `:json`, `:csv`) | `:console` |
| `output_file` | Output file path | `nil` (console only) |

## Rails Integration

The gem automatically integrates with Rails and will:

- Discover product URLs using `Product.find_each` and `product_page_path`
- Discover category URLs using `Category.find_each` and `category_page_path`
- Set appropriate defaults for development/production environments
- Provide rake tasks for easy integration

## CI/CD Integration

The crawler returns appropriate exit codes for CI/CD:

```bash
# Exit code 0 if healthy, 1 if issues found
rake crawler:crawl

# Use in GitHub Actions, CircleCI, etc.
- name: Check site health
  run: bundle exec rake crawler:crawl
```

## Output Formats

### Console (Default)
Colorized, human-readable output with progress bars and summary.

### JSON
```json
{
  "summary": {
    "pages_checked": 623,
    "failed_pages": 2,
    "broken_links": 1,
    "healthy": false,
    "timestamp": "2025-07-23T10:30:00Z"
  },
  "failed_pages": [...],
  "broken_links": [...],
  "all_urls_checked": [...]
}
```

### CSV
Structured CSV format perfect for importing into spreadsheets or databases.

## Development

After checking out the repo, run:

```bash
bin/setup
bundle exec rspec
```

To release a new version:

1. Update the version number in `version.rb`
2. Run `bundle exec rake release`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/rails_crawler.

## License

The gem is available as open source under the [MIT License](https://opensource.org/licenses/MIT).

## Roadmap

- [ ] Sitemap.xml parsing support
- [ ] Custom authentication (basic auth, cookies)
- [ ] Performance metrics (response times, page sizes)
- [ ] Email notifications for CI/CD failures
- [ ] More output formats (XML, HTML reports)