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
    @current_player_session = PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
    @current_player = @current_player_session&.player
    @current_player_session
  end

  def request_player_authentication
    head :unauthorized
  end
end
