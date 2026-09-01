module Play
  class BaseController < ActionController::Base
    layout "player"

    private

    def authenticate_player!
      @player = Player.find_by(token: params[:token])
      redirect_to new_player_path unless @player
    end
  end
end
