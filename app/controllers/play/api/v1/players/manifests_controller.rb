module Play
  module Api
    module V1
      module Players
        class ManifestsController < Play::Api::V1::BaseController
          before_action :authenticate_player!

          def show
            @screen_content = current_player.screen&.active_screen_content

            render template: "api/v1/players/manifests/show", formats: [ :json ]
          end
        end
      end
    end
  end
end
