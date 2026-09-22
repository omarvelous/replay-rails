module Listings
  module Extractors
    class StructuredData
      def initialize(html)
        @doc = Nokogiri::HTML(html)
      end

      def call
        data = extract_json_ld || {}

        {
          address: extract_address(data),
          price: extract_price(data),
          beds: extract_integer(data, "numberOfRooms"),
          baths: extract_integer(data, "numberOfBathroomsTotal"),
          sqft: extract_sqft(data),
          description: data["description"] || og("description"),
          photo_urls: extract_photos(data),
          property_type: nil,
          listing_type: nil
        }
      end

      private

      def extract_json_ld
        @doc.css('script[type="application/ld+json"]').each do |script|
          parsed = JSON.parse(script.text) rescue next
          # Handle arrays of structured data
          parsed = parsed.is_a?(Array) ? parsed.first : parsed
          return parsed if real_estate_type?(parsed)
        end
        nil
      end

      def real_estate_type?(data)
        type = data["@type"].to_s
        %w[RealEstateListing Product Residence Apartment House SingleFamilyResidence].include?(type)
      end

      def extract_address(data)
        addr = data["address"]
        return nil unless addr.is_a?(Hash)

        parts = [
          addr["streetAddress"],
          addr["addressLocality"],
          addr["addressRegion"],
          addr["postalCode"]
        ].compact

        parts.any? ? parts.join(", ") : nil
      end

      def extract_price(data)
        offers = data["offers"]
        price = if offers.is_a?(Hash)
                  offers["price"]
        else
                  data["price"]
        end
        price.to_i if price.present?
      end

      def extract_integer(data, key)
        value = data[key]
        value.to_i if value.present?
      end

      def extract_sqft(data)
        floor_size = data["floorSize"]
        return floor_size["value"].to_i if floor_size.is_a?(Hash) && floor_size["value"].present?
        nil
      end

      def extract_photos(data)
        images = data["image"]
        urls = case images
        when Array then images.select { |i| i.is_a?(String) }
        when String then [ images ]
        else []
        end

        # Supplement with og:image if no images found
        if urls.empty?
          og_image = og("image")
          urls << og_image if og_image.present?
        end

        urls
      end

      def og(property)
        tag = @doc.at_css("meta[property='og:#{property}']")
        tag&.[]("content")
      end
    end
  end
end
