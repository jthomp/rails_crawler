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

  desc "Crawl only Rails model-based URLs (products, categories, etc.)"
  task :crawl_models => :environment do
    base_url = ENV["BASE_URL"] || RailsCrawler.configuration.base_url
    
    if base_url.nil?
      puts "❌ No base URL configured. Set BASE_URL environment variable or configure in initializer.".colorize(:red)
      exit 1
    end

    puts "🚀 Crawling Rails model URLs..."
    
    failed_urls = []
    total_checked = 0

    # Check products
    if defined?(Product)
      puts "📦 Checking product pages..."
      Product.find_each.with_index do |product, index|
        begin
          path = Rails.application.routes.url_helpers.product_page_path(product)
          url = "#{base_url}#{path}"
          
          uri = URI(url)
          response = Net::HTTP.get_response(uri)
          total_checked += 1
          
          unless (200..299).include?(response.code.to_i)
            failed_urls << { url: url, status: response.code, model: "Product", id: product.id }
            puts "  ❌ Product #{product.id}: #{url} (#{response.code})".colorize(:red)
          else
            puts "  ✅ Product #{product.id}" if index % 50 == 0
          end
        rescue => e
          failed_urls << { url: url, status: "error", model: "Product", id: product.id, error: e.message }
          puts "  ❌ Product #{product.id}: #{e.message}".colorize(:red)
        end
      end
    end

    # Check categories
    if defined?(Category)
      puts "📂 Checking category pages..."
      Category.find_each.with_index do |category, index|
        begin
          path = Rails.application.routes.url_helpers.category_page_path(category)
          url = "#{base_url}#{path}"
          
          uri = URI(url)
          response = Net::HTTP.get_response(uri)
          total_checked += 1
          
          unless (200..299).include?(response.code.to_i)
            failed_urls << { url: url, status: response.code, model: "Category", id: category.id }
            puts "  ❌ Category #{category.id}: #{url} (#{response.code})".colorize(:red)
          else
            puts "  ✅ Category #{category.id}" if index % 20 == 0
          end
        rescue => e
          failed_urls << { url: url, status: "error", model: "Category", id: category.id, error: e.message }
          puts "  ❌ Category #{category.id}: #{e.message}".colorize(:red)
        end
      end
    end
    
    # TODO: Add static pages

    # Report results
    puts "\n" + "="*50
    puts "📊 RESULTS".colorize(:blue).bold
    puts "="*50
    puts "Total URLs checked: #{total_checked}"
    puts "Failed URLs: #{failed_urls.count}".colorize(failed_urls.empty? ? :green : :red)
    
    if failed_urls.any?
      puts "\n🚨 Failed URLs:".colorize(:red).bold
      failed_urls.each do |failure|
        puts "  #{failure[:model]} ID #{failure[:id]}: #{failure[:url]} (#{failure[:status]})"
        puts "    Error: #{failure[:error]}" if failure[:error]
      end
    else
      puts "\n🎉 All model URLs are working!".colorize(:green).bold
    end

    exit 1 unless failed_urls.empty?
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
  end
end