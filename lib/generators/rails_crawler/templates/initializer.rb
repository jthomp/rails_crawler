# frozen_string_literal: true

RailsCrawler.configure do |config|
  # Base URL for crawling (defaults to localhost:3000 in development)
  # config.base_url = 'http://localhost:3000'
  # config.base_url = ENV['APP_URL'] # Use environment variable

  # Maximum number of concurrent requests
  config.max_concurrent = 5

  # Delay between requests (in seconds) to be nice to your server
  config.delay_between_requests = 0.1

  # Whether to follow external links (links to other domains)
  config.follow_external_links = false

  # User agent string
  config.user_agent = "RailsCrawler/#{RailsCrawler::VERSION}"

  # Request timeout in seconds
  config.timeout = 30

  # Patterns to exclude from crawling (regexes)
  config.exclude_patterns = [
    /\.(pdf|zip|tar|gz|jpg|jpeg|png|gif|svg|ico)$/i,
    /\/admin/,
    /\/api/
  ]

  # Patterns to include (if specified, only URLs matching these will be crawled)
  # config.include_patterns = [/\/products/, /\/categories/]

  # The model-backed pages `rake crawler:crawl_models` checks and the full
  # crawl seeds its queue from. The defaults cover Product, Category, Page,
  # Article, ArticleTag, Faq and Zone; a check whose model or route this app
  # lacks is skipped. Add your own or replace the list:
  # config.model_checks << RailsCrawler::ModelCheck.new("Recipe", routes: :recipe_path, scope: :published)

  # Fixed paths checked alongside the model pages (listing pages and such)
  # config.static_paths = ["/articles", "/faqs", "/new-arrivals"]

  # Default output format (:console, :json, :csv)
  config.output_format = :console

  # Output file (optional, defaults to console output)
  # config.output_file = 'crawl_report.json'
end