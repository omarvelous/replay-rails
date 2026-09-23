module PlayerAuthentication
  extend ActiveSupport::Concern

  private

  def authenticate_player!
    resume_player_session || request_player_authentication
  end

  def current_player_session
    resume_player_session
    @current_player_session
  end

  def current_player
    resume_player_session
    @current_player
  end

  def resume_player_session
    return @current_player_session if defined?(@current_player_session)
    @current_player_session = find_session_from_bearer || find_session_from_cookie
    @current_player = @current_player_session&.player
    @current_player_session
  end

  def find_session_from_bearer
    if header = request.headers["Authorization"]&.delete_prefix("Bearer ")
      session_id = Rails.application.message_verifier(:player_session).verify(header)
      PlayerSession.active.find_by(id: session_id)
    end
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def find_session_from_cookie
    PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
  end

  def request_player_authentication
    head :unauthorized
  end
end
