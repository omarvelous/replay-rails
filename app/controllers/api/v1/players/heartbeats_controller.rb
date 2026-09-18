module Api
  module V1
    module Players
      class HeartbeatsController < Api::V1::BaseController
        before_action :authenticate_player!

        def create
          result = RecordHeartbeat.new(
            player: current_player,
            session: current_player_session,
            ip_address: request.remote_ip,
            user_agent: request.user_agent,
            params: params
          ).call

          if result.success?
            head :no_content
          else
            render_error result.error, status: :gone
          end
        end
      end
    end
  end
end
