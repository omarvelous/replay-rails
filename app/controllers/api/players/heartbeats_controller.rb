module Api
  module Players
    class HeartbeatsController < Api::BaseController
      before_action :authenticate_player!

      # POST /players/:token/heartbeat
      def create
        return render json: { error: "unpaired" }, status: :gone unless @player.screen

        ua_changed = @player.user_agent != request.user_agent

        @player.update!(
          last_heartbeat_at: Time.current,
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          screen_width: params[:screen_width] || @player.screen_width,
          screen_height: params[:screen_height] || @player.screen_height
        )

        @player.parse_user_agent! if ua_changed
        render json: { ok: true }
      end
    end
  end
end
