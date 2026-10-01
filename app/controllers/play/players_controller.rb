module Play
  class PlayersController < Play::BaseController
    before_action :authenticate_from_token, only: :show
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

    private

    def authenticate_from_token
      return unless params[:token].present?

      session_id = Rails.application.message_verifier(:player_session).verify(params[:token])
      player_session = PlayerSession.active.find_by(id: session_id)
      return unless player_session

      cookies.signed[:player_session_id] = {
        value: player_session.id,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: 1.year.from_now
      }
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end
  end
end
