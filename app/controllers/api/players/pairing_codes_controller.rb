module Api
  module Players
    class PairingCodesController < Api::BaseController
      before_action :authenticate_player!

      # POST /players/:token/pairing_code
      def create
        @player.refresh_pairing_code!

        render json: {
          pairing_code: @player.pairing_code,
          expires_in: 600
        }, status: :created
      end
    end
  end
end
