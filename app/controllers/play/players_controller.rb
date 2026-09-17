module Play
  class PlayersController < Play::BaseController
    before_action :authenticate_player!, only: :show
    skip_forgery_protection only: :authenticate

    # GET / — check localStorage for token, redirect accordingly
    def landing
    end

    # GET /players/:id — playback content (auth via cookie)
    def show
      @screen = @player.screen

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

    # POST /players/authenticate — set player session cookie (same-origin from pairing JS)
    def authenticate
      session = PlayerSession.active.find_by(id: params[:session_id])
      if session
        cookies.signed[:player_session_id] = {
          value: session.id,
          httponly: true,
          secure: Rails.env.production?,
          same_site: :lax,
          expires: 1.year.from_now,
          domain: :all
        }
        render json: { ok: true }
      else
        render json: { error: "invalid session" }, status: :unauthorized
      end
    end

    # GET /players/new — pairing screen
    def new
    end
  end
end
