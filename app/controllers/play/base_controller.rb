module Play
  class BaseController < ActionController::Base
    layout "player"

    private

    def authenticate_player!
      token = cookies.signed[:player_token]
      @player = Player.find_by(token: token)
      redirect_to new_player_path unless @player
    end
  end
end
