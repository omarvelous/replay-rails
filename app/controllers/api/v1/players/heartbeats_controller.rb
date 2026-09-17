module Api
  module V1
    module Players
      class HeartbeatsController < Api::V1::BaseController
        before_action :authenticate_player!

        # POST /v1/player/heartbeat
        def create
          return render_error("unpaired", status: :gone) unless @player.screen

          ua_changed = @player.user_agent != request.user_agent

          @player_session.update!(last_active_at: Time.current)
          @player.update!(
            last_heartbeat_at: Time.current,
            ip_address: request.remote_ip,
            user_agent: request.user_agent,
            screen_width: params[:screen_width] || @player.screen_width,
            screen_height: params[:screen_height] || @player.screen_height
          )

          ParseDeviceInfo.new(player: @player).call if ua_changed
          head :no_content
        end
      end
    end
  end
end
