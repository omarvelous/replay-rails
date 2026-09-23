require "net/http"

module Listings
  class PhotoImportJob < ApplicationJob
    queue_as :default

    def perform(listing_id, photo_urls)
      listing = Listing.find(listing_id)

      photo_urls.each do |url|
        attach_photo(listing, url)
      rescue StandardError => e
        Rails.logger.warn("Failed to import photo from #{url}: #{e.message}")
      end
    end

    private

    def attach_photo(listing, url)
      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)
      return unless response.is_a?(Net::HTTPSuccess)

      filename = File.basename(uri.path).presence || "imported_photo.jpg"
      content_type = response.content_type || "image/jpeg"

      listing.photos.attach(
        io: StringIO.new(response.body),
        filename: filename,
        content_type: content_type
      )
    end
  end
end
