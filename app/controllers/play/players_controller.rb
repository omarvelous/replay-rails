module Play
  class PlayersController < Play::BaseController
    skip_forgery_protection only: :create
    rate_limit to: 10, within: 1.minute, only: :create, by: -> { request.remote_ip }
    before_action :authenticate_player!, only: :show

    # GET / and GET /player — playback content (HTML) or player status (JSON)
    def show
      @player = current_player
      @screen = current_player.screen

      respond_to do |format|
        format.json { render json: { paired: @player.paired? } }
        format.html do
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
      end
    end

    # POST /player — register a new device + set cookie
    def create
      result = RegisterPlayer.new(
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        params: player_params
      ).call

      cookies.signed[:player_session_id] = {
        value: result.session.id,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: 1.year.from_now,
        domain: :all
      }

      render json: {
        pairing_code: result.player.pairing_code,
        public_id: result.player.public_id,
        expires_at: result.player.pairing_code_expires_at
      }, status: :created
    end

    # GET /player/new — pairing screen
    def new
    end

    private

    def player_params
      params.permit(:screen_width, :screen_height, :touch_capable, :app_version)
    end
  end
end
