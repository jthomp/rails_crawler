# frozen_string_literal: true

require 'json'
require 'csv'
require 'colorize'

module RailsCrawler
  class Report
    attr_reader :visited_urls, :failed_pages, :broken_links

    def initialize(visited_urls, failed_pages, broken_links)
      @visited_urls = visited_urls
      @failed_pages = failed_pages
      @broken_links = broken_links
    end

    def generate(format = :console, output_file = nil)
      case format
      when :console
        generate_console_report
      when :json
        generate_json_report(output_file)
      when :csv
        generate_csv_report(output_file)
      else
        raise ArgumentError, "Unknown format: #{format}"
      end
    end

    def healthy?
      @failed_pages.empty? && @broken_links.empty?
    end

    def summary
      {
        pages_checked: @visited_urls.length,
        failed_pages: @failed_pages.length,
        broken_links: @broken_links.length,
        healthy: healthy?,
        timestamp: Time.now.iso8601
      }
    end

    private

    def generate_console_report
      puts "\n" + "="*60
      puts "🕷️  CRAWL REPORT".colorize(:blue).bold
      puts "="*60
      
      puts "📊 Summary:".colorize(:blue).bold
      puts "  Pages checked: #{@visited_urls.length}"
      puts "  Failed pages: #{@failed_pages.length}".colorize(@failed_pages.empty? ? :green : :red)
      puts "  Broken links: #{@broken_links.length}".colorize(@broken_links.empty? ? :green : :red)
      puts "  Status: #{healthy? ? '✅ HEALTHY' : '❌ ISSUES FOUND'}".colorize(healthy? ? :green : :red).bold
      
      if @failed_pages.any?
        puts "\n🚨 Failed Pages:".colorize(:red).bold
        @failed_pages.each do |failure|
          puts "  ❌ #{failure[:url]}".colorize(:red)
          puts "      Status: #{failure[:status]} - #{failure[:error]}"
          puts "      Time: #{failure[:timestamp]}"
          puts
        end
      end
      
      if @broken_links.any?
        puts "\n🔗 Broken Links:".colorize(:red).bold
        @broken_links.each do |broken|
          puts "  🔗 #{broken[:broken_link]}".colorize(:red)
          puts "      Found on: #{broken[:found_on]}"
          puts "      Error: #{broken[:error]}"
          puts "      Time: #{broken[:timestamp]}"
          puts
        end
      end
      
      if healthy?
        puts "\n🎉 All pages and links are working correctly!".colorize(:green).bold
      end
      
      puts "="*60
    end

    def generate_json_report(output_file)
      report_data = {
        summary: summary,
        failed_pages: @failed_pages,
        broken_links: @broken_links,
        all_urls_checked: @visited_urls
      }
      
      json_output = JSON.pretty_generate(report_data)
      
      if output_file
        File.write(output_file, json_output)
        puts "📄 JSON report saved to: #{output_file}".colorize(:green)
      else
        puts json_output
      end
      
      json_output
    end

    def generate_csv_report(output_file)
      output_file ||= "crawl_report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
      
      CSV.open(output_file, 'w') do |csv|
        # Summary section
        csv << ['SUMMARY']
        csv << ['Pages Checked', @visited_urls.length]
        csv << ['Failed Pages', @failed_pages.length]
        csv << ['Broken Links', @broken_links.length]
        csv << ['Status', healthy? ? 'HEALTHY' : 'ISSUES FOUND']
        csv << ['Timestamp', Time.now.iso8601]
        csv << []
        
        # Failed pages section
        if @failed_pages.any?
          csv << ['FAILED PAGES']
          csv << ['URL', 'Status', 'Error', 'Timestamp']
          @failed_pages.each do |failure|
            csv << [failure[:url], failure[:status], failure[:error], failure[:timestamp]]
          end
          csv << []
        end
        
        # Broken links section
        if @broken_links.any?
          csv << ['BROKEN LINKS']
          csv << ['Broken Link', 'Found On', 'Error', 'Timestamp']
          @broken_links.each do |broken|
            csv << [broken[:broken_link], broken[:found_on], broken[:error], broken[:timestamp]]
          end
          csv << []
        end
        
        # All URLs section
        csv << ['ALL URLS CHECKED']
        @visited_urls.each { |url| csv << [url] }
      end
      
      puts "📄 CSV report saved to: #{output_file}".colorize(:green)
      output_file
    end
  end
end