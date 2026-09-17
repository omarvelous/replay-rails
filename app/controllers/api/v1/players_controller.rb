module Api
  module V1
    class PlayersController < Api::V1::BaseController
      rate_limit to: 10, within: 1.minute, only: :create, by: -> { request.remote_ip }
      before_action :authenticate_player!, only: :show

      # GET /v1/player — player status (singular, auth via bearer/cookie)
      def show
        render_data(paired: @player.paired?)
      end

      # POST /v1/players — register a new device
      def create
        player = Player.create!(
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          app_version: params[:app_version],
          screen_width: params[:screen_width],
          screen_height: params[:screen_height],
          touch_capable: params[:touch_capable]
        )
        ParseDeviceInfo.new(player: player).call

        render_data({
          pairing_code: player.pairing_code,
          token: player.token,
          public_id: player.public_id,
          expires_in: 600
        }, status: :created)
      end
    end
  end
end
