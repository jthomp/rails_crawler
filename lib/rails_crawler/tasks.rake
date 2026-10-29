# Suppress RubyGems platform warnings
$VERBOSE = nil

namespace :crawler do
  desc "Crawl the entire site for broken pages and links"
  task :crawl => :environment do
    base_url = ENV["BASE_URL"] || RailsCrawler.configuration.base_url

    if base_url.nil?
      puts "❌ No base URL configured. Set BASE_URL environment variable or configure in initializer.".colorize(:red)
      exit 1
    end

    options = {}
    options[:output_format] = ENV["FORMAT"].to_sym if ENV["FORMAT"]
    options[:output_file] = ENV["OUTPUT_FILE"] if ENV["OUTPUT_FILE"]
    options[:max_concurrent] = ENV["MAX_CONCURRENT"].to_i if ENV["MAX_CONCURRENT"]
    options[:follow_external_links] = ENV["FOLLOW_EXTERNAL"] == "true" if ENV["FOLLOW_EXTERNAL"]

    puts "🚀 Starting site crawl..."
    puts "   Base URL: #{base_url}"
    puts "   Max Concurrent: #{options[:max_concurrent] || RailsCrawler.configuration.max_concurrent}"
    puts

    report = RailsCrawler.crawl(base_url, options)
    
    # Exit with error code if issues found (useful for CI/CD)
    exit 1 unless report.healthy?
  end

  desc "Check every model-backed page (products, categories, pages, articles, FAQs, zones, ...)"
  task :crawl_models => :environment do
    base_url = ENV["BASE_URL"] || RailsCrawler.configuration.base_url

    if base_url.nil?
      puts "❌ No base URL configured. Set BASE_URL environment variable or configure in initializer.".colorize(:red)
      exit 1
    end

    config = RailsCrawler.configuration
    base_url = base_url.chomp("/")
    checked_urls = []
    failed_pages = []

    # Requests one page, recording it in checked_urls and, if it is anything
    # but a 2xx, in failed_pages.
    check_url = lambda do |url, label|
      response = RailsCrawler::Request.get(url)
      checked_urls << url

      unless (200..299).cover?(response.code.to_i)
        failed_pages << { url: url, status: response.code.to_i, error: "#{label}: #{response.message}",
                          timestamp: Time.now.iso8601 }
        puts "  ❌ #{label}: #{url} (#{response.code})".colorize(:red)
      end

      sleep(config.delay_between_requests) if config.delay_between_requests.to_f.positive?
    rescue StandardError => e
      checked_urls << url
      failed_pages << { url: url, status: "exception", error: "#{label}: #{e.message}", timestamp: Time.now.iso8601 }
      puts "  ❌ #{label}: #{url} - #{e.message}".colorize(:red)
    end

    puts "🚀 Checking model pages at #{base_url}..."

    config.model_checks.each do |check|
      if (reason = check.skip_reason)
        puts "⏭️  #{check.label}: skipped (#{reason})".colorize(:yellow)
        next
      end

      puts "🔎 Checking #{check.label} pages..."
      before_checked = checked_urls.length
      before_failed = failed_pages.length

      begin
        check.each_page do |record, path|
          check_url.call("#{base_url}#{path}", "#{check.label} #{record.id}")
        end
      rescue StandardError => e
        puts "  ⚠️  Could not list #{check.label} pages: #{e.message}".colorize(:yellow)
        failed_pages << { url: "#{check.label} pages", status: "exception", error: e.message,
                          timestamp: Time.now.iso8601 }
      end

      count = checked_urls.length - before_checked
      failures = failed_pages.length - before_failed
      puts "   #{check.label}: #{count} checked, #{failures} failed".colorize(failures.zero? ? :green : :red)
    end

    if config.static_paths.any?
      puts "🔎 Checking static paths..."
      config.static_paths.each { |path| check_url.call("#{base_url}#{path}", "Static #{path}") }
    end

    report = RailsCrawler::Report.new(checked_urls, failed_pages, [])
    report.generate(ENV["FORMAT"]&.to_sym || config.output_format, ENV["OUTPUT_FILE"] || config.output_file)

    exit 1 unless report.healthy?
  end

  desc "Show crawler configuration"
  task :config do
    config = RailsCrawler.configuration
    puts "🔧 RailsCrawler Configuration:".colorize(:blue).bold
    puts "   Base URL: #{config.base_url || "Not set"}"
    puts "   Max Concurrent: #{config.max_concurrent}"
    puts "   Delay Between Requests: #{config.delay_between_requests}s"
    puts "   Follow External Links: #{config.follow_external_links}"
    puts "   User Agent: #{config.user_agent}"
    puts "   Timeout: #{config.timeout}s"
    puts "   Output Format: #{config.output_format}"
    puts "   Output File: #{config.output_file || "Console only"}"
    puts "   Exclude Patterns: #{config.exclude_patterns.map(&:source).join(", ")}"
    puts "   Include Patterns: #{config.include_patterns.any? ? config.include_patterns.map(&:source).join(", ") : "All URLs"}"
    puts "   Model Checks: #{config.model_checks.map(&:label).join(", ")}"
    puts "   Static Paths: #{config.static_paths.any? ? config.static_paths.join(", ") : "None"}"
  end
end