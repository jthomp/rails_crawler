# frozen_string_literal: true

require "bundler/setup"
require "rails_crawler"
require "webmock/rspec"
require "vcr"
require "timeout"

# Set environment variable to indicate we're running tests
ENV['RSPEC_RUNNING'] = 'true'

# Disable real HTTP requests during tests
WebMock.disable_net_connect!(allow_localhost: false)

# Configure VCR for recording real HTTP requests if needed
VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Reset configuration before each test
  config.before(:each) do
    RailsCrawler.configuration = RailsCrawler::Configuration.new
  end
end