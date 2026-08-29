module Api
  class PlayersController < Api::BaseController
    before_action :authenticate_player!, only: :show

    # GET /players/:token — player status
    def show
      render json: { paired: @player.paired?, screen_id: @player.screen&.id }
    end

    # POST /players — register a new device
    def create
      player = Player.create!(
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )

      render json: {
        pairing_code: player.pairing_code,
        token: player.token,
        expires_in: 600
      }, status: :created
    end
  end
end
