module Api
  module Players
    class HeartbeatsController < Api::BaseController
      before_action :authenticate_player!

      # POST /players/:token/heartbeat
      def create
        @player.update!(
          last_heartbeat_at: Time.current,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        )
        render json: { ok: true }
      end
    end
  end
end
