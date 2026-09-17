module Play
  class BaseController < ActionController::Base
    layout "player"

    private

    def authenticate_player!
      @player_session = PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
      @player = @player_session&.player
      redirect_to new_player_path unless @player
    end
  end
end
