module Api
  module V1
    module Players
      class ManifestsController < Api::V1::BaseController
        before_action :authenticate_player!

        def show
          @screen_content = @player.screen&.active_screen_content

          if @screen_content
            render :show, formats: [ :json ]
          else
            render_data(content: nil)
          end
        end
      end
    end
  end
end
