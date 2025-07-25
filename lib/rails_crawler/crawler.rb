require "net/http"
require "uri"
require "nokogiri"
require "set"
require "concurrent"
require "colorize"

module RailsCrawler
  class Crawler
    attr_reader :base_url, :visited_urls, :failed_pages, :broken_links, :options

    def initialize(base_url, options = {})
      @base_url = base_url.chomp("/")
      @options = RailsCrawler.configuration.to_h.merge(options)
      @visited_urls = Concurrent::Set.new
      @failed_pages = Concurrent::Array.new
      @broken_links = Concurrent::Array.new
      @url_queue = Concurrent::Array.new
      @pages_checked = Concurrent::AtomicFixnum.new(0)
      @start_time = Time.now
    end

    def crawl_site
      puts "🕷️  Starting crawl of #{@base_url}".colorize(:blue)
      puts "🔧 max_concurrent setting: #{@options[:max_concurrent].inspect} (#{@options[:max_concurrent].class})" if ENV["DEBUG_WEBMOCK"]
      
      initial_urls = get_initial_urls
      @url_queue.concat(initial_urls)
      
      # Always use sequential processing to avoid Ruby closure bugs
      # The concurrent version has unresolved closure variable capture issues
      crawl_site_sequential
    end
    
    # Sequential crawling method - works reliably without closure issues
    def crawl_site_sequential
      puts "🔄 Using sequential processing (avoids Ruby closure bugs)" if ENV["DEBUG_WEBMOCK"]
      
      iteration = 0
      max_iterations = 1000
      
      while !@url_queue.empty? && iteration < max_iterations
        iteration += 1
        url = @url_queue.shift
        
        puts "📋 Iteration #{iteration}: Processing #{url}" if ENV["DEBUG_WEBMOCK"]
        puts "    Queue remaining: #{@url_queue.length}" if ENV["DEBUG_WEBMOCK"]
        
        next if url.nil? || @visited_urls.include?(url) || should_exclude_url?(url)
        
        # Process this URL directly without futures/threads
        @visited_urls.add(url)
        count = @pages_checked.increment
        
        show_progress if count % 5 == 0 || ENV["VERBOSE"]
        
        begin
          uri = URI(url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = uri.scheme == "https"
          http.read_timeout = @options[:timeout]
          http.open_timeout = @options[:timeout]
          
          request = Net::HTTP::Get.new(uri)
          request["User-Agent"] = @options[:user_agent]
          
          response = http.request(request)
          
          case response.code.to_i
          when 200..299
            puts "  ✓ #{url} (#{response.code})".colorize(:green) if ENV["VERBOSE"] || ENV["DEBUG_WEBMOCK"]
            extract_and_queue_links(url, response.body) if response.body
          when 300..399
            location = response["location"]
            if location
              puts "  → #{url} redirects to #{location} (#{response.code})".colorize(:yellow) if ENV["VERBOSE"] || ENV["DEBUG_WEBMOCK"]
              resolved_location = resolve_url(url, location)
              @url_queue << resolved_location unless @visited_urls.include?(resolved_location)
            end
          else
            puts "  ✗ #{url} (#{response.code})".colorize(:red) unless ENV["RSPEC_RUNNING"] || (!ENV["VERBOSE"] && !ENV["DEBUG_WEBMOCK"])
            @failed_pages << {
              url: url,
              status: response.code.to_i,
              error: response.message,
              timestamp: Time.now.iso8601
            }
          end
          
        rescue => e
          puts "  ✗ #{url} - Exception: #{e.message}".colorize(:red) unless ENV["RSPEC_RUNNING"] || (!ENV["VERBOSE"] && !ENV["DEBUG_WEBMOCK"])
          @failed_pages << {
            url: url,
            status: "exception",
            error: e.message,
            timestamp: Time.now.iso8601
          }
        end
        
        sleep(@options[:delay_between_requests]) if @options[:delay_between_requests] > 0
      end
      
      show_final_progress
      
      report = Report.new(@visited_urls.to_a, @failed_pages.to_a, @broken_links.to_a)
      report.generate(@options[:output_format], @options[:output_file])
      
      report
    end

    private

    def get_initial_urls
      urls = [@base_url]
      
      # If running in Rails context, get URLs from routes
      if defined?(Rails) && Rails.application
        begin
          urls.concat(extract_rails_urls)
        rescue => e
          puts "⚠️  Could not extract Rails URLs: #{e.message}".colorize(:yellow)
        end
      end
      
      urls
    end

    def extract_rails_urls
      urls = []
      
      # Try to get product URLs
      if defined?(Product) && Product.respond_to?(:find_each)
        Product.find_each do |product|
          if Rails.application.routes.url_helpers.respond_to?(:product_page_path)
            path = Rails.application.routes.url_helpers.product_page_path(product.permalink)
            urls << "#{@base_url}#{path}"
          end
        end
      end
      
      # Try to get category URLs
      if defined?(Category) && Category.respond_to?(:find_each)
        Category.find_each do |category|
          if Rails.application.routes.url_helpers.respond_to?(:category_page_path)
            path = Rails.application.routes.url_helpers.category_page_path(category.permalink)
            urls << "#{@base_url}#{path}"
          end
        end
      end

      # Try to get static page URLs
      if defined?(Page) && Page.respond_to?(:find_each)
        Page.find_each do |page|
          if Rails.application.routes.url_helpers.respond_to?(:static_page_path)
            path = Rails.application.routes.url_helpers.static_page_path(page.permalink)
            urls << "#{@base_url}#{path}"
          end
        end
      end
      
      urls
    end

    def show_progress
      count = @pages_checked.value
      elapsed = Time.now - @start_time
      rate = count > 0 ? (count / elapsed).round(1) : 0
      
      print "\r🕷️  Checked: #{count} pages | Rate: #{rate}/sec | Queue: #{@url_queue.length} | Failed: #{@failed_pages.length}     "
      $stdout.flush
    end

    def show_final_progress
      count = @pages_checked.value
      elapsed = Time.now - @start_time
      rate = count > 0 ? (count / elapsed).round(1) : 0
      
      puts "\n✅ Crawl completed: #{count} pages in #{elapsed.round(1)}s (#{rate}/sec)"
    end

    def check_page(url)
      return if @visited_urls.include?(url) || should_exclude_url?(url)
      
      @visited_urls.add(url)
      count = @pages_checked.increment
      
      # Show progress every 5 pages or if verbose
      show_progress if count % 5 == 0 || ENV["VERBOSE"]
      
      begin
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.read_timeout = @options[:timeout]
        http.open_timeout = @options[:timeout]
        
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = @options[:user_agent]
        
        response = http.request(request)
        
        case response.code.to_i
        when 200..299
          puts "  ✓ #{url} (#{response.code})".colorize(:green) if ENV["VERBOSE"]
          extract_and_queue_links(url, response.body) if response.body
        when 300..399
          location = response["location"]
          if location
            puts "  → #{url} redirects to #{location} (#{response.code})".colorize(:yellow) if ENV["VERBOSE"]
            resolved_location = resolve_url(url, location)
            @url_queue << resolved_location unless @visited_urls.include?(resolved_location)
          end
        else
          puts "  ✗ #{url} (#{response.code})".colorize(:red)
          @failed_pages << {
            url: url,
            status: response.code.to_i,
            error: response.message,
            timestamp: Time.now.iso8601
          }
        end
        
      rescue => e
        puts "  ✗ #{url} - Exception: #{e.message}".colorize(:red) if ENV["VERBOSE"]
        @failed_pages << {
          url: url,
          status: "exception",
          error: e.message,
          timestamp: Time.now.iso8601
        }
      end
      
      sleep(@options[:delay_between_requests]) if @options[:delay_between_requests] > 0
    end

    def extract_and_queue_links(page_url, html)
      return unless html
      
      begin
        doc = Nokogiri::HTML(html)
        links_found = []
        
        doc.css("a[href]").each do |link|
          href = link["href"]&.strip
          next if href.nil? || href.empty?
          
          begin
            link_url = resolve_url(page_url, href)
            next if should_exclude_url?(link_url)
            
            # Check if it"s an internal link or if we should follow external links
            link_uri = URI(link_url)
            base_uri = URI(@base_url)
            
            if link_uri.host.nil? || link_uri.host == base_uri.host || @options[:follow_external_links]
              unless @visited_urls.include?(link_url)
                @url_queue << link_url
                links_found << link_url
                puts "  📎 Queued: #{link_url}" if ENV["VERBOSE"] || ENV["DEBUG_WEBMOCK"]
              else
                puts "  ↻ Already visited: #{link_url}" if ENV["VERBOSE"] || ENV["DEBUG_WEBMOCK"]
              end
            else
              puts "  🌐 External (skipped): #{link_url}" if ENV["VERBOSE"] || ENV["DEBUG_WEBMOCK"]
            end
            
          rescue URI::InvalidURIError => e
            @broken_links << {
              found_on: page_url,
              broken_link: href,
              error: "Invalid URI: #{e.message}",
              timestamp: Time.now.iso8601
            }
          end
        end
        
        puts "  📋 Found #{links_found.length} new links on #{page_url}: #{links_found}" if ENV["DEBUG_WEBMOCK"]
        
      rescue => e
        puts "  ⚠️  Error parsing HTML for #{page_url}: #{e.message}".colorize(:yellow) if ENV["VERBOSE"]
      end
    end

    def resolve_url(base_url, href)
      uri = URI.join(base_url, href)
      # Remove fragments
      uri.fragment = nil
      uri.to_s
    end

    def should_exclude_url?(url)
      return true if @options[:exclude_patterns].any? { |pattern| url.match?(pattern) }
      return false if @options[:include_patterns].empty?
      
      @options[:include_patterns].any? { |pattern| url.match?(pattern) }
    end
  end
end