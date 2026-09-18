module Play
  class PairingCodesController < Play::BaseController
    before_action :authenticate_player!

    def create
      result = RefreshPairingCode.new(player: current_player).call

      render json: {
        pairing_code: result.pairing_code,
        expires_in: result.expires_in
      }, status: :created
    end
  end
end
