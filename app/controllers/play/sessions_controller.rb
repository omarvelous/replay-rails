module Play
  class SessionsController < Play::BaseController
    # POST /player/session — set player session cookie after pairing
    def create
      player_session = PlayerSession.active.find_by(id: params[:session_id])
      if player_session
        cookies.signed[:player_session_id] = {
          value: player_session.id,
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
  end
end
