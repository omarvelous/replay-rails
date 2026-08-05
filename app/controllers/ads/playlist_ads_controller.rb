module Ads
  class PlaylistAdsController < ::PlaylistAdsController
    private

      def parent
        @parent ||= Current.account.ads.find(params[:ad_id])
      end
  end
end
