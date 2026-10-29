# frozen_string_literal: true

module RailsCrawler
  class Configuration
    attr_accessor :base_url, :max_concurrent, :delay_between_requests, 
                  :follow_external_links, :user_agent, :timeout,
                  :exclude_patterns, :include_patterns,
                  :output_format, :output_file,
                  :model_checks, :static_paths

    def initialize
      @base_url = nil
      @max_concurrent = 5
      @delay_between_requests = 0.1
      @follow_external_links = false
      @user_agent = "RailsCrawler/#{VERSION}"
      @timeout = 30
      @exclude_patterns = [/\.(pdf|zip|tar|gz|jpg|jpeg|png|gif|svg|ico)$/i]
      @include_patterns = []
      @output_format = :console # :console, :json, :csv
      @output_file = nil
      # The model-backed page types to check; see ModelCheck.defaults.
      @model_checks = ModelCheck.defaults
      # Fixed paths ("/articles", "/faqs") checked alongside the model pages.
      @static_paths = []
    end

    def to_h
      {
        base_url: @base_url,
        max_concurrent: @max_concurrent,
        delay_between_requests: @delay_between_requests,
        follow_external_links: @follow_external_links,
        user_agent: @user_agent,
        timeout: @timeout,
        exclude_patterns: @exclude_patterns,
        include_patterns: @include_patterns,
        output_format: @output_format,
        output_file: @output_file,
        model_checks: @model_checks,
        static_paths: @static_paths
      }
    end
  end
end