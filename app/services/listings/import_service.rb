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

    def fetch_page
      response = Net::HTTP.get_response(@uri)
      raise FetchError, "Failed to fetch #{@url}: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
      response.body
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
