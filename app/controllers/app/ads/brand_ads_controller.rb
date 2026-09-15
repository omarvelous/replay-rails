module App
  module Ads
    class BrandAdsController < App::Ads::BaseController
      private

        def adable_class = ::Ads::BrandAd
    end
  end
end
