# frozen_string_literal: true

require "net/http"
require "uri"

module RailsCrawler
  # One GET with the configured user agent and timeouts. Redirects are not
  # followed; the caller decides what a 3xx means.
  module Request
    def self.get(url, options = {})
      options = RailsCrawler.configuration.to_h.merge(options)
      uri = URI(url)

      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = options[:user_agent]

      http_for(uri, options[:timeout]).request(request)
    end

    def self.http_for(uri, timeout)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.read_timeout = timeout
      http.open_timeout = timeout
      http
    end
  end
end
