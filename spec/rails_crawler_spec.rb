# frozen_string_literal: true

require "spec_helper"
require "webmock/rspec"

RSpec.describe RailsCrawler do
  it "has a version number" do
    expect(RailsCrawler::VERSION).not_to be nil
  end

  describe ".configure" do
    it "yields configuration" do
      expect { |b| RailsCrawler.configure(&b) }.to yield_with_args(RailsCrawler.configuration)
    end

    it "allows setting configuration options" do
      RailsCrawler.configure do |config|
        config.base_url = "http://example.com"
        config.max_concurrent = 10
      end

      expect(RailsCrawler.configuration.base_url).to eq("http://example.com")
      expect(RailsCrawler.configuration.max_concurrent).to eq(10)
    end
  end

  describe ".crawl" do
    before do
      # Suppress console output during tests
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      allow($stdout).to receive(:print)
      allow($stdout).to receive(:flush)
      
      WebMock.stub_request(:get, "http://example.com")
        .to_return(status: 200, body: "<html><body><a href='/test'>Test</a></body></html>")

      WebMock.stub_request(:get, "http://example.com/test")
        .to_return(status: 200, body: "<html><body>Test page</body></html>")
    end

    it "crawls a site and returns a report" do
      report = RailsCrawler.crawl("http://example.com")
      
      expect(report).to be_a(RailsCrawler::Report)
      expect(report.visited_urls).to include("http://example.com")
      expect(report.healthy?).to be true
    end

    it "raises error when no base URL provided" do
      expect { RailsCrawler.crawl }.to raise_error(RailsCrawler::Error, "Base URL is required")
    end
  end
end