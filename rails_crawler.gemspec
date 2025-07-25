# frozen_string_literal: true

require_relative "lib/rails_crawler/version"

Gem::Specification.new do |spec|
  spec.name = "rails_crawler"
  spec.version = RailsCrawler::VERSION
  spec.authors = ["Justin Thompson"]
  spec.email = ["justin@jthomp.dev"]

  spec.summary = "A Rails-friendly web crawler for checking page health and broken links"
  spec.description = "Crawl your Rails application to detect broken pages, HTTP errors, and broken links. Perfect for CI/CD health checks."
  spec.homepage = "https://github.com/jthomp/rails_crawler"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "colorize", "~> 0.8"
  spec.add_dependency "concurrent-ruby", "~> 1.1"
  spec.add_dependency "csv", "~> 3.3"
  spec.add_dependency "nokogiri", "~> 1.13"

  # Development dependencies
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.21"
  spec.add_development_dependency "simplecov", "~> 0.13"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "webmock", "~> 3.14"
end
