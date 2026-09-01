module Play
  class PlayersController < Play::BaseController
    before_action :authenticate_player!, only: :show

    # GET / — check localStorage for token, redirect accordingly
    def landing
    end

    # GET /players/:token — playback content
    def show
      @screen = @player.screen

      unless @screen
        return render :unpaired
      end

      @playlist = @screen.screen_playlists.find_by(active: true)&.playlist

      if @playlist
        @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
      else
        render :idle
      end
    end

    # GET /players/new — pairing screen
    def new
    end
  end
end
