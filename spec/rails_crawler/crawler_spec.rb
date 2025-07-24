require 'spec_helper'

RSpec.describe RailsCrawler::Crawler do
  let(:base_url) { 'http://example.com' }
  let(:crawler) { described_class.new(base_url, max_concurrent: 1, delay_between_requests: 0) }

  describe '#initialize' do
    it 'sets the base URL without trailing slash' do
      crawler_with_slash = described_class.new('http://example.com/')
      expect(crawler_with_slash.base_url).to eq('http://example.com')
    end

    it 'initializes empty collections' do
      expect(crawler.visited_urls).to be_empty
      expect(crawler.failed_pages).to be_empty
      expect(crawler.broken_links).to be_empty
    end
  end

  describe '#crawl_site' do
    before do
      # Suppress console output during tests unless debugging
      unless ENV['DEBUG_WEBMOCK']
        allow($stdout).to receive(:write)
        allow($stdout).to receive(:flush)
        allow($stdout).to receive(:puts)
        allow_any_instance_of(described_class).to receive(:puts)
        allow_any_instance_of(described_class).to receive(:print)
        allow_any_instance_of(described_class).to receive(:show_progress)
        allow_any_instance_of(described_class).to receive(:show_final_progress)
      end
      
      stub_request(:get, "http://example.com")
        .to_return(status: 200, body: homepage_html, headers: { 'Content-Type' => 'text/html' })
      
      stub_request(:get, "http://example.com:80")
        .to_return(status: 200, body: homepage_html, headers: { 'Content-Type' => 'text/html' })
      
      stub_request(:get, "http://example.com/about")
        .to_return(status: 200, body: about_html, headers: { 'Content-Type' => 'text/html' })
      
      stub_request(:get, "http://example.com:80/about")
        .to_return(status: 200, body: about_html, headers: { 'Content-Type' => 'text/html' })
      
      stub_request(:get, "http://example.com/contact")
        .to_return(status: 404, body: "Not Found")
      
      stub_request(:get, "http://example.com:80/contact")
        .to_return(status: 404, body: "Not Found")
    end

    let(:homepage_html) do
      <<~HTML
        <html>
          <body>
            <a href="/about">About</a>
            <a href="/contact">Contact</a>
            <a href="http://external.com">External</a>
          </body>
        </html>
      HTML
    end

    let(:about_html) do
      <<~HTML
        <html>
          <body>
            <h1>About Us</h1>
            <a href="/">Home</a>
          </body>
        </html>
      HTML
    end

    it 'crawls all reachable pages' do
      report = nil
      
      Timeout.timeout(10) do
        report = crawler.crawl_site
      end
      
      visited_urls = crawler.visited_urls.to_a
      expect(visited_urls).to include('http://example.com')
      expect(visited_urls).to include('http://example.com/about')
      expect(report).to be_a(RailsCrawler::Report)
    end

    it 'detects failed pages' do
      report = nil
      
      Timeout.timeout(10) do
        report = crawler.crawl_site
      end
      
      failed_page = crawler.failed_pages.find { |p| p[:url].include?('/contact') }
      expect(failed_page).not_to be_nil
      expect(failed_page[:status]).to eq(404)
    end

    it 'does not follow external links by default' do
      report = nil
      
      Timeout.timeout(10) do
        report = crawler.crawl_site
      end
      
      expect(crawler.visited_urls.to_a).not_to include('http://external.com')
    end

    context 'when follow_external_links is true' do
      let(:crawler) { described_class.new(base_url, follow_external_links: true, max_concurrent: 1, delay_between_requests: 0) }

      before do
        stub_request(:get, "http://external.com")
          .to_return(status: 200, body: "<html><body>External site</body></html>")
      end

      it 'follows external links' do
        report = nil
        
        Timeout.timeout(10) do
          report = crawler.crawl_site
        end
        
        visited_urls = crawler.visited_urls.to_a
        expect(visited_urls).to include('http://external.com')
      end
    end

    context 'with higher concurrency' do
      let(:concurrent_crawler) { described_class.new(base_url, max_concurrent: 3, delay_between_requests: 0) }

      it 'processes URLs concurrently' do
        report = nil
        
        Timeout.timeout(10) do
          report = concurrent_crawler.crawl_site
        end
        
        visited_urls = concurrent_crawler.visited_urls.to_a
        expect(visited_urls).to include('http://example.com')
        expect(visited_urls).to include('http://example.com/about')
        
        failed_page = concurrent_crawler.failed_pages.find { |p| p[:url].include?('/contact') }
        expect(failed_page).not_to be_nil
      end
    end
  end

  describe '#direct_page_processing' do
    before do
      stub_request(:get, "http://example.com")
        .to_return(status: 200, body: homepage_html, headers: { 'Content-Type' => 'text/html' })
      
      stub_request(:get, "http://example.com/about")
        .to_return(status: 200, body: about_html, headers: { 'Content-Type' => 'text/html' })
      
      stub_request(:get, "http://example.com/contact")
        .to_return(status: 404, body: "Not Found")
    end

    let(:homepage_html) do
      <<~HTML
        <html>
          <body>
            <a href="/about">About</a>
            <a href="/contact">Contact</a>
            <a href="http://external.com">External</a>
          </body>
        </html>
      HTML
    end

    let(:about_html) do
      <<~HTML
        <html>
          <body>
            <h1>About Us</h1>
            <a href="/">Home</a>
          </body>
        </html>
      HTML
    end

    it 'processes individual pages correctly when called directly' do
      test_crawler = described_class.new(base_url, max_concurrent: 1, delay_between_requests: 0)
      
      puts "\n=== DIRECT CHECK_PAGE TEST ===" if ENV['DEBUG']
      puts "Initial state:" if ENV['DEBUG']
      puts "  visited_urls: #{test_crawler.visited_urls.to_a.inspect}" if ENV['DEBUG']
      puts "  failed_pages: #{test_crawler.failed_pages.length}" if ENV['DEBUG']
      
      puts "\nTesting homepage..." if ENV['DEBUG']
      test_crawler.send(:check_page, 'http://example.com')
      puts "  visited_urls: #{test_crawler.visited_urls.to_a.inspect}" if ENV['DEBUG']
      puts "  queue: #{test_crawler.instance_variable_get(:@url_queue).to_a.inspect}" if ENV['DEBUG']
      
      puts "\nTesting about page..." if ENV['DEBUG']
      test_crawler.send(:check_page, 'http://example.com/about')
      puts "  visited_urls: #{test_crawler.visited_urls.to_a.inspect}" if ENV['DEBUG']
      
      puts "\nTesting contact page..." if ENV['DEBUG']
      test_crawler.send(:check_page, 'http://example.com/contact')
      puts "  visited_urls: #{test_crawler.visited_urls.to_a.inspect}" if ENV['DEBUG']
      puts "  failed_pages: #{test_crawler.failed_pages.length}" if ENV['DEBUG']
      
      visited_urls = test_crawler.visited_urls.to_a
      expect(visited_urls).to include('http://example.com')
      expect(visited_urls).to include('http://example.com/about')
      expect(visited_urls).to include('http://example.com/contact')
      
      failed_page = test_crawler.failed_pages.find { |p| p[:url] == 'http://example.com/contact' }
      expect(failed_page).not_to be_nil
    end
  end

  describe '#should_exclude_url?' do
    let(:crawler) { described_class.new(base_url, exclude_patterns: [/\.pdf$/]) }

    it 'excludes URLs matching exclude patterns' do
      expect(crawler.send(:should_exclude_url?, 'http://example.com/file.pdf')).to be true
    end

    it 'includes URLs not matching exclude patterns' do
      expect(crawler.send(:should_exclude_url?, 'http://example.com/page.html')).to be false
    end
  end

  describe '#resolve_url' do
    it 'resolves relative URLs' do
      result = crawler.send(:resolve_url, 'http://example.com/page', 'about')
      expect(result).to eq('http://example.com/about')
    end

    it 'resolves absolute URLs' do
      result = crawler.send(:resolve_url, 'http://example.com/page', '/contact')
      expect(result).to eq('http://example.com/contact')
    end

    it 'removes fragments' do
      result = crawler.send(:resolve_url, 'http://example.com/', '/page#section')
      expect(result).to eq('http://example.com/page')
    end
  end

  describe '#extract_and_queue_links' do
    let(:html) do
      <<~HTML
        <html>
          <body>
            <a href="/test1">Test 1</a>
            <a href="/test2">Test 2</a>
            <a href="http://external.com">External</a>
          </body>
        </html>
      HTML
    end

    it 'extracts and queues internal links' do
      crawler.send(:extract_and_queue_links, 'http://example.com', html)
      
      queued_urls = crawler.instance_variable_get(:@url_queue).to_a
      expect(queued_urls).to include('http://example.com/test1')
      expect(queued_urls).to include('http://example.com/test2')
    end

    it 'does not queue external links by default' do
      crawler.send(:extract_and_queue_links, 'http://example.com', html)
      
      queued_urls = crawler.instance_variable_get(:@url_queue).to_a
      expect(queued_urls).not_to include('http://external.com')
    end

    context 'when follow_external_links is true' do
      let(:external_crawler) { described_class.new(base_url, follow_external_links: true) }

      it 'queues external links' do
        external_crawler.send(:extract_and_queue_links, 'http://example.com', html)
        
        queued_urls = external_crawler.instance_variable_get(:@url_queue).to_a
        expect(queued_urls).to include('http://external.com')
      end
    end
  end

  describe 'error handling' do
    before do
      stub_request(:get, "http://example.com")
        .to_raise(StandardError.new("Connection failed"))
    end

    it 'handles network errors gracefully' do
      expect { crawler.send(:check_page, 'http://example.com') }.not_to raise_error
      
      failed_page = crawler.failed_pages.find { |p| p[:url] == 'http://example.com' }
      expect(failed_page).not_to be_nil
      expect(failed_page[:status]).to eq('exception')
      expect(failed_page[:error]).to eq('Connection failed')
    end
  end
end