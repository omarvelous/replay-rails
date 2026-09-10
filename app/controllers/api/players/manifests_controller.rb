module Api
  module Players
    class ManifestsController < Api::BaseController
      before_action :authenticate_player!

      def show
        @screen_content = @player.screen&.active_screen_content

        if @screen_content
          render :show, formats: [:json]
        else
          render json: { content: nil }
        end
      end
    end
  end
end
