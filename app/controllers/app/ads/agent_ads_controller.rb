module App
  module Ads
    class AgentAdsController < App::Ads::BaseController
      private

        def adable_class = ::Ads::AgentAd

        def adable_params
          params.require(:agent_ad).permit(:agent_id)
        end
    end
  end
end
