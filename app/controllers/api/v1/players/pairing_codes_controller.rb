module Api
  module V1
    module Players
      class PairingCodesController < Api::V1::BaseController
        before_action :authenticate_player!

        def create
          result = RefreshPairingCode.new(player: current_player).call

          render_data({
            pairing_code: result.pairing_code,
            expires_at: result.expires_at
          }, status: :created)
        end
      end
    end
  end
end
