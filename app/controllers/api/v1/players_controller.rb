module Api
  module V1
    class PlayersController < Api::V1::BaseController
      rate_limit to: 10, within: 1.minute, only: :create, by: -> { request.remote_ip }
      before_action :authenticate_player!, only: :show

      # GET /v1/player — player status
      def show
        render_data(paired: current_player.paired?)
      end

      # POST /v1/players — register a new device
      def create
        result = RegisterPlayer.new(
          ip_address: request.remote_ip,
          user_agent: request.user_agent,
          params: player_params
        ).call

        render_data({
          pairing_code: result.player.pairing_code,
          session_id: result.session.id,
          public_id: result.player.public_id,
          expires_at: result.player.pairing_code_expires_at
        }, status: :created)
      end

      private

      def player_params
        params.permit(:screen_width, :screen_height, :touch_capable, :app_version)
      end
    end
  end
end
