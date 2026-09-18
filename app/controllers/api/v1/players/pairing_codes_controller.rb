module Api
  module V1
    module Players
      class PairingCodesController < Api::V1::BaseController
        before_action :authenticate_player!

        # POST /v1/players/:token/pairing_code
        def create
          if current_player.pairing_code_valid?
            expires_in = (current_player.pairing_code_expires_at - Time.current).to_i
          else
            current_player.refresh_pairing_code!
            expires_in = 600
          end

          render_data({
            pairing_code: current_player.pairing_code,
            expires_in: expires_in
          }, status: :created)
        end
      end
    end
  end
end
