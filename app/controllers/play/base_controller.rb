module Play
  class BaseController < ActionController::Base
    layout "player"

    private

    def authenticate_player!
      @player = Player.find_by(token: params[:token])
      head :unauthorized unless @player
    end
  end
end
