module Listings
  module Extractors
    class StreetEasy
      def initialize(html)
        @doc = Nokogiri::HTML(html)
        @structured = StructuredData.new(html)
      end

      def call
        structured = @structured.call

        {
          address: extract_address || structured[:address],
          price: structured[:price],
          beds: extract_detail("beds")&.to_i || structured[:beds],
          baths: extract_detail("baths")&.to_i || structured[:baths],
          sqft: extract_sqft || structured[:sqft],
          description: extract_description || structured[:description],
          photo_urls: extract_carousel_photos.presence || structured[:photo_urls],
          floor_plan_urls: extract_floor_plans,
          property_type: nil,
          listing_type: nil
        }
      end

      private

      def extract_address
        title = @doc.at_css("h1.building-title")
        title&.text&.strip.presence
      end

      def extract_detail(name)
        cell = @doc.at_css("[data-testid='#{name}']")
        return nil unless cell

        cell.at_css(".detail-value")&.text&.strip.presence
      end

      def extract_sqft
        raw = extract_detail("sqft")
        return nil unless raw

        raw.gsub(/[^0-9]/, "").to_i
      end

      def extract_description
        desc = @doc.at_css(".listing-description")
        desc&.text&.strip.presence
      end

      def extract_carousel_photos
        @doc.css(".image-carousel .carousel-img").filter_map do |img|
          img["src"].presence
        end
      end

      def extract_floor_plans
        @doc.css(".floor-plan-section .floor-plan-img").filter_map do |img|
          img["src"].presence
        end
      end
    end
  end
end
