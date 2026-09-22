module Listings
  module Extractors
    class StreetEasy
      def initialize(html)
        @doc = Nokogiri::HTML(html)
        @graph = parse_graph
      end

      def call
        {
          address: extract_address,
          price: extract_price,
          beds: extract_beds,
          baths: extract_baths,
          sqft: extract_sqft,
          description: extract_description,
          photo_urls: extract_photos,
          property_type: extract_property_type,
          listing_type: extract_listing_type
        }
      end

      private

      # JSON-LD on StreetEasy uses @graph with nested ItemPage > about (RealEstateListing) + mainEntity (Apartment)
      def parse_graph
        @doc.css('script[type="application/ld+json"]').each do |script|
          parsed = JSON.parse(script.text) rescue next
          return parsed["@graph"] if parsed.is_a?(Hash) && parsed["@graph"]
        end
        []
      end

      def item_page
        @item_page ||= @graph.find { |n| n["@type"] == "ItemPage" } || {}
      end

      def listing_data
        @listing_data ||= item_page.dig("about") || {}
      end

      def main_entity
        @main_entity ||= item_page.dig("mainEntity") || {}
      end

      # Address from mainEntity.address (PostalAddress)
      def extract_address
        addr = main_entity["address"]
        return extract_address_from_title unless addr.is_a?(Hash)

        parts = [
          addr["streetAddress"],
          addr["addressLocality"]&.titleize,
          addr["addressRegion"],
          addr["postalCode"]
        ].compact

        parts.any? ? parts.join(", ") : extract_address_from_title
      end

      def extract_address_from_title
        title = og("title")
        return nil unless title

        # "60 Cedar Street #15G in Bushwick, Brooklyn | StreetEasy"
        title.sub(/\s+\|.*/, "").sub(/\s+in\s+.*/, "").strip.presence
      end

      # Price from listing offers
      def extract_price
        price = listing_data.dig("offers", "price")
        price.to_i if price.present?
      end

      # Beds/baths/sqft aren't in StreetEasy's structured data.
      # Parse from og:description or og:title patterns.
      def extract_beds
        match_in_text(/(\d+)\s*(?:bed(?:room)?s?\b|br\b)/i)
      end

      def extract_baths
        match_in_text(/(\d+(?:\.\d+)?)\s*(?:bath(?:room)?s?\b|ba\b)/i)
      end

      def extract_sqft
        match_in_text(/(\d[\d,]*)\s*(?:sq\.?\s*ft|sqft|sf)\b/i) { |m| m.delete(",").to_i }
      end

      def match_in_text(pattern, &block)
        [ og("description"), og("title"), listing_data["description"] ].compact.each do |text|
          match = text.match(pattern)
          next unless match

          return block ? block.call(match[1]) : match[1].to_i
        end
        nil
      end

      def extract_description
        listing_data["description"].presence || og("description")
      end

      # StreetEasy puts all photos as multiple og:image meta tags
      def extract_photos
        @doc.css('meta[property="og:image"]').filter_map { |m| m["content"].presence }
      end

      def extract_property_type
        type = main_entity["@type"]
        case type
        when "Apartment" then "apartment"
        when "House", "SingleFamilyResidence" then "house"
        when "Residence" then "condo"
        end
      end

      def extract_listing_type
        price_label = main_entity.dig("additionalProperty")
          &.find { |p| p["name"]&.match?(/rent/i) }

        price_label ? "for_rent" : nil
      end

      def og(property)
        tag = @doc.at_css("meta[property='og:#{property}']")
        tag&.[]("content")
      end
    end
  end
end
