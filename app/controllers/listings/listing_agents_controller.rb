module Listings
  class ListingAgentsController < ::ListingAgentsController
    private

      def parent
        @parent ||= Current.account.listings.find(params[:listing_id])
      end
  end
end
