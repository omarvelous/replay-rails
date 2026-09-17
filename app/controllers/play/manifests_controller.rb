module Play
  class ManifestsController < Play::BaseController
    before_action :authenticate_player!

    # GET /player/manifest
    def show
      @screen_content = current_player.screen&.active_screen_content

      if @screen_content
        render template: "api/v1/players/manifests/show", formats: [ :json ]
      else
        render json: { data: { content: nil } }
      end
    end
  end
end
