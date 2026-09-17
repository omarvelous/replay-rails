module Play
  class HeartbeatsController < Play::BaseController
    before_action :authenticate_player!

    # POST /player/heartbeat
    def create
      return head(:gone) unless current_player.screen

      ua_changed = current_player.user_agent != request.user_agent

      current_player_session.update!(last_active_at: Time.current)
      current_player.update!(
        last_heartbeat_at: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        screen_width: params[:screen_width] || current_player.screen_width,
        screen_height: params[:screen_height] || current_player.screen_height
      )

      ParseDeviceInfo.new(player: current_player).call if ua_changed
      head :no_content
    end
  end
end
