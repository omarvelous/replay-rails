module Play
  module Api
    module V1
      module Players
        class HeartbeatsController < Play::Api::V1::BaseController
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
              screen_content = current_player.screen&.active_screen_content
              contentable = screen_content&.contentable
              content_version = [ screen_content, contentable ].compact.map(&:updated_at).max&.to_i

              render_data({
                status: "ok",
                content_version: content_version
              })
            else
              render_error result.error, status: :gone
            end
          end
        end
      end
    end
  end
end
