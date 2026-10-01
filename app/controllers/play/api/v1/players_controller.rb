module Play
  module Api
    module V1
      class PlayersController < Play::Api::V1::BaseController
        rate_limit to: 10, within: 1.minute, only: :create, by: -> { request.remote_ip }, unless: -> { Rails.env.local? }
        before_action :authenticate_player!, only: :show

        # GET /api/v1/player — player status
        def show
          set_session_cookie_if_missing
          render_data(paired: current_player.paired?)
        end

        # POST /api/v1/players — register a new device + set cookie
        def create
          result = RegisterPlayer.new(
            ip_address: request.remote_ip,
            user_agent: request.user_agent,
            params: player_params
          ).call

          cookies.signed[:player_session_id] = {
            value: result.session.id,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax,
            expires: 1.year.from_now
          }

          render_data({
            pairing_code: result.player.pairing_code,
            token: result.session.bearer_token,
            public_id: result.player.public_id,
            expires_at: result.player.pairing_code_expires_at
          }, status: :created)
        end

        private

        def player_params
          params.permit(:screen_width, :screen_height, :touch_capable, :app_version)
        end

        def set_session_cookie_if_missing
          return unless current_player_session

          cookie_session_id = cookies.signed[:player_session_id]
          return if cookie_session_id == current_player_session.id

          cookies.signed[:player_session_id] = {
            value: current_player_session.id,
            httponly: true,
            secure: Rails.env.production?,
            same_site: :lax,
            expires: 1.year.from_now
          }
        end
      end
    end
  end
end
