module Api
  module V1
    module Players
      class HeartbeatsController < Api::V1::BaseController
        before_action :authenticate_player!

        # POST /v1/players/:token/heartbeat
        def create
          return render_error("unpaired", status: :gone) unless @player.screen

          ua_changed = @player.user_agent != request.user_agent

          @player.update!(
            last_heartbeat_at: Time.current,
            ip_address: request.remote_ip,
            user_agent: request.user_agent,
            screen_width: params[:screen_width] || @player.screen_width,
            screen_height: params[:screen_height] || @player.screen_height
          )

          @player.parse_user_agent! if ua_changed
          head :no_content
        end
      end
    end
  end
end
