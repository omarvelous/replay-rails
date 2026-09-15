module App
  module Ads
    class ListingAdsController < App::Ads::BaseController
      private

        def adable_class = ::Ads::ListingAd

        def adable_params
          params.require(:listing_ad).permit(
            :listing_id, :badge,
            :event_date, :event_start_time, :event_end_time,
            :original_price, :sold_price, :sold_date
          )
        end
    end
  end
end
