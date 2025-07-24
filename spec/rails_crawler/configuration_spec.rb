# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RailsCrawler::Configuration do
  let(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default values' do
      expect(config.base_url).to be_nil
      expect(config.max_concurrent).to eq(5)
      expect(config.delay_between_requests).to eq(0.1)
      expect(config.follow_external_links).to be false
      expect(config.user_agent).to include('RailsCrawler')
      expect(config.timeout).to eq(30)
      expect(config.exclude_patterns).not_to be_empty
      expect(config.include_patterns).to be_empty
      expect(config.output_format).to eq(:console)
      expect(config.output_file).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns configuration as hash' do
      config.base_url = 'http://example.com'
      config.max_concurrent = 10
      
      hash = config.to_h
      
      expect(hash[:base_url]).to eq('http://example.com')
      expect(hash[:max_concurrent]).to eq(10)
      expect(hash).to have_key(:delay_between_requests)
      expect(hash).to have_key(:follow_external_links)
    end
  end
end