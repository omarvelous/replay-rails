module App
  module Ads
    class CollectionAdsController < App::Ads::BaseController
      private

        def adable_class = ::Ads::CollectionAd

        def ad_defaults = { layout: "grid" }

        def ad_params
          params.require(:ad).permit(:headline, :body, :theme, :image)
        end

        def adable_params
          params.require(:collection_ad).permit(:collection_title, member_ad_ids: [])
        end

        def load_form_data
          @available_ads = Current.account.ads.includes(:adable).where.not(adable_type: "Ads::CollectionAd").order(:headline)
        end
    end
  end
end
