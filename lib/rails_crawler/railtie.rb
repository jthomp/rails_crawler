# frozen_string_literal: true

require 'rails/railtie'

module RailsCrawler
  class Railtie < Rails::Railtie
    railtie_name :rails_crawler

    rake_tasks do
      load 'rails_crawler/tasks.rake'
    end

    initializer 'rails_crawler.configure' do |app|
      # Set default base URL from Rails if not configured
      if RailsCrawler.configuration.base_url.nil?
        if Rails.env.development?
          RailsCrawler.configuration.base_url = 'http://localhost:3000'
        elsif Rails.env.production? && ENV['APP_URL']
          RailsCrawler.configuration.base_url = ENV['APP_URL']
        end
      end
    end
  end
end