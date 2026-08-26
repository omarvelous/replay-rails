class PlayerApiController < ActionController::Base
  before_action :authenticate_player!, only: %i[ play heartbeat ]

  # POST /player/register
  def register
    @player = Player.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )

    respond_to do |format|
      format.html { render "player_api/register", layout: "player" }
      format.json { render json: { pairing_code: @player.pairing_code, token: @player.token, expires_in: 600 } }
    end
  end

  # GET /player/status
  def status
    player = Player.find_by!(pairing_code: params[:code]&.upcase)

    if player.paired?
      render json: { paired: true, token: player.token, screen_id: player.screen.id }
    else
      render json: { paired: false }
    end
  end

  # GET /player/play
  def play
    @screen = @player.screen

    unless @screen
      return render "player_api/unpaired", layout: "player"
    end

    playlist = @screen.screen_playlists.find_by(active: true)&.playlist

    if playlist
      @playlist_ads = playlist.playlist_ads.includes(:ad).order(:position)
      render "player_api/play", layout: "player"
    else
      render "player_api/idle", layout: "player"
    end
  end

  # POST /player/heartbeat
  def heartbeat
    @player.update!(
      last_heartbeat_at: Time.current,
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
    render json: { ok: true }
  end

  private

    def authenticate_player!
      token = request.headers["Authorization"]&.delete_prefix("Bearer ")
      @player = Player.find_by(token: token)
      render json: { error: "Unauthorized" }, status: :unauthorized unless @player
    end
end
