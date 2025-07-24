# frozen_string_literal: true

# Suppress RubyGems platform warnings
original_verbose = $VERBOSE
$VERBOSE = nil

require_relative "rails_crawler/version"
require_relative "rails_crawler/configuration"
require_relative "rails_crawler/crawler"
require_relative "rails_crawler/report"

# Restore original verbosity
$VERBOSE = original_verbose

module RailsCrawler
  class Error < StandardError; end

  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.crawl(base_url = nil, options = {})
    base_url ||= configuration.base_url
    raise Error, "Base URL is required" unless base_url

    crawler_options = configuration.to_h.merge(options)
    crawler = Crawler.new(base_url, crawler_options)
    crawler.crawl_site
  end
end

# Load Rails integration if Rails is present
if defined?(Rails)
  require_relative "rails_crawler/railtie"
end