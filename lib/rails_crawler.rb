# frozen_string_literal: true

# Suppress RubyGems platform warnings
original_verbose = $VERBOSE
$VERBOSE = nil

require "uri"

require_relative "rails_crawler/version"
require_relative "rails_crawler/model_check"
require_relative "rails_crawler/configuration"
require_relative "rails_crawler/request"
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

  # Hosts reached over plain http when the base URL names no scheme.
  LOOPBACK_HOST = /\A(localhost|.+\.localhost|127(\.\d{1,3}){3}|0\.0\.0\.0|\[::1\])\z/i

  # The base URL as an absolute http(s) URL with no trailing slash. A URL
  # given without a scheme ("www.example.com", "localhost:3000") gets https,
  # or http for a loopback host; without one every request would fail.
  def self.normalize_base_url(base_url)
    url = base_url.to_s.strip
    raise Error, "Base URL is required" if url.empty?

    url = with_scheme(url)
    uri = URI.parse(url)
    raise URI::InvalidURIError unless uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?

    url.chomp("/")
  rescue URI::InvalidURIError
    raise Error, "Base URL must be an http(s) URL, got #{base_url.inspect}"
  end

  def self.with_scheme(url)
    return url if url.match?(%r{\A[a-z][a-z0-9+.-]*://}i)

    url = url.delete_prefix("//")
    host = url[%r{\A(\[[^\]]*\]|[^:/?#]*)}]
    "#{host.match?(LOOPBACK_HOST) ? "http" : "https"}://#{url}"
  end
  private_class_method :with_scheme

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