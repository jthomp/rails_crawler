# frozen_string_literal: true

require "rails/generators"

module RailsCrawler
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Generate RailsCrawler initializer"

      def create_initializer_file
        template "initializer.rb", "config/initializers/rails_crawler.rb"
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

      private

      def readme(path)
        say File.read(File.join(File.dirname(__FILE__), "templates", path))
      end
    end
  end
end