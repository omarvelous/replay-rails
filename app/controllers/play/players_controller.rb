module Play
  class PlayersController < Play::BaseController
    before_action :authenticate_player!, only: :show

    # GET / and GET /player — playback content (HTML)
    def show
      @player = current_player
      @screen = current_player.screen

      unless @screen
        return render :unpaired
      end

      case @screen.content_type
      when :playlist
        @playlist = @screen.active_content
        @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
      when :experience
        @experience = @screen.active_content
        @listing = @experience.listing
        @agent = @experience.default_agent
        render :experience
      else
        render :idle
      end
    end

    # GET /player/new — pairing screen
    def new
    end
  end
end
