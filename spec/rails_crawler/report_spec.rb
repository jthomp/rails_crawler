# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'tempfile'

RSpec.describe RailsCrawler::Report do
  let(:visited_urls) { ['http://example.com', 'http://example.com/about'] }
  let(:failed_pages) { [{ url: 'http://example.com/404', status: 404, error: 'Not Found' }] }
  let(:broken_links) { [{ found_on: 'http://example.com', broken_link: '/broken', error: '404' }] }
  let(:report) { described_class.new(visited_urls, failed_pages, broken_links) }

  describe '#initialize' do
    it 'sets the data correctly' do
      expect(report.visited_urls).to eq(visited_urls)
      expect(report.failed_pages).to eq(failed_pages)
      expect(report.broken_links).to eq(broken_links)
    end
  end

  describe '#healthy?' do
    context 'when there are no failures' do
      let(:report) { described_class.new(visited_urls, [], []) }
      
      it 'returns true' do
        expect(report.healthy?).to be true
      end
    end

    context 'when there are failures' do
      it 'returns false' do
        expect(report.healthy?).to be false
      end
    end
  end

  describe '#summary' do
    it 'returns correct summary data' do
      summary = report.summary
      
      expect(summary[:pages_checked]).to eq(2)
      expect(summary[:failed_pages]).to eq(1)
      expect(summary[:broken_links]).to eq(1)
      expect(summary[:healthy]).to be false
      expect(summary[:timestamp]).to be_a(String)
    end
  end

  describe '#generate' do
    before do
      # Suppress console output during tests
      allow($stdout).to receive(:puts)
      allow($stdout).to receive(:write)
      allow($stdout).to receive(:print)
    end

    context 'with console format' do
      it 'generates console output' do
        expect { report.generate(:console) }.not_to raise_error
      end
    end

    context 'with json format' do
      it 'generates JSON output' do
        json_output = report.generate(:json)
        parsed = JSON.parse(json_output)
        
        expect(parsed['summary']['pages_checked']).to eq(2)
        expect(parsed['failed_pages'].length).to eq(1)
        expect(parsed['broken_links'].length).to eq(1)
      end

      it 'saves to file when output_file is provided' do
        Tempfile.create('test_report.json') do |file|
          report.generate(:json, file.path)
          
          content = File.read(file.path)
          parsed = JSON.parse(content)
          expect(parsed['summary']['pages_checked']).to eq(2)
        end
      end
    end

    context 'with csv format' do
      it 'generates CSV file' do
        Tempfile.create('test_report.csv') do |file|
          result_file = report.generate(:csv, file.path)
          
          expect(File.exist?(result_file)).to be true
          content = File.read(result_file)
          expect(content).to include('SUMMARY')
          expect(content).to include('FAILED PAGES')
          expect(content).to include('BROKEN LINKS')
        end
      end
    end

    context 'with unknown format' do
      it 'raises an error' do
        expect { report.generate(:unknown) }.to raise_error(ArgumentError, /Unknown format/)
      end
    end
  end
end