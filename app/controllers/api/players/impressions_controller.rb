module Api
  module Players
    class ImpressionsController < Api::BaseController
      before_action :authenticate_player!

      # POST /players/:token/impressions
      def create
        screen = @player.screen
        return render json: { error: "unpaired" }, status: :gone unless screen

        Impression.create!(
          ad_id: params[:ad_id],
          screen: screen,
          player: @player,
          site: screen.site,
          playlist_id: params[:playlist_id],
          account: screen.site.account,
          position: params[:position],
          duration: params[:duration]
        )
        head :created
      end
    end
  end
end
