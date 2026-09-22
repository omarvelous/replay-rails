require "net/http"

module Listings
  class ImportService
    class InvalidUrlError < StandardError; end
    class FetchError < StandardError; end

    PARSER_MAP = {
      /streeteasy\.com/ => Extractors::StreetEasy
    }.freeze

    def self.call(url:)
      new(url).call
    end

    def initialize(url)
      @url = url
      @uri = parse_url!(url)
    end

    def call
      html = fetch_page
      extractor = parser_for(@uri)
      result = extractor.new(html).call
      result.merge(source_url: @url)
    end

    private

    def parse_url!(url)
      uri = URI.parse(url)
      raise InvalidUrlError, "Invalid URL: #{url}" unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      uri
    rescue URI::InvalidURIError
      raise InvalidUrlError, "Invalid URL: #{url}"
    end

    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    MAX_REDIRECTS = 3

    def fetch_page
      uri = @uri
      MAX_REDIRECTS.times do
        response = make_request(uri)
        if response.is_a?(Net::HTTPSuccess)
          return response.body.force_encoding("UTF-8")
        elsif response.is_a?(Net::HTTPRedirection)
          uri = URI.parse(response["location"])
        else
          raise FetchError, "Could not fetch that URL. The site returned HTTP #{response.code}."
        end
      end
      raise FetchError, "Too many redirects fetching #{@url}"
    end

    def make_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 10
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = "text/html"
      http.request(request)
    end

    def parser_for(uri)
      host = uri.host
      PARSER_MAP.each do |pattern, klass|
        return klass if host.match?(pattern)
      end
      Extractors::StructuredData
    end
  end
end
