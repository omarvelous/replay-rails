module Play
  class HeartbeatsController < Play::BaseController
    before_action :authenticate_player!

    def create
      result = RecordHeartbeat.new(
        player: current_player,
        session: current_player_session,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        params: params
      ).call

      if result.success?
        head :no_content
      else
        head :gone
      end
    end
  end
end
