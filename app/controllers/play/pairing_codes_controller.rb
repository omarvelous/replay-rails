module Play
  class PairingCodesController < Play::BaseController
    before_action :authenticate_player!

    # POST /player/pairing_code
    def create
      if current_player.pairing_code_valid?
        expires_in = (current_player.pairing_code_expires_at - Time.current).to_i
      else
        current_player.refresh_pairing_code!
        expires_in = 600
      end

      render json: {
        pairing_code: current_player.pairing_code,
        expires_in: expires_in
      }, status: :created
    end
  end
end
