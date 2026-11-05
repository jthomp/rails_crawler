# frozen_string_literal: true

require "bundler/setup"
require "rails_crawler"
require "webmock/rspec"
require "timeout"

# Set environment variable to indicate we're running tests
ENV["RSPEC_RUNNING"] = "true"

# Disable real HTTP requests during tests
WebMock.disable_net_connect!(allow_localhost: false)

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