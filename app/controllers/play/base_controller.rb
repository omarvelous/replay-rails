module Play
  class BaseController < ActionController::Base
    include PlayerAuthentication

    layout "player"

    private

    def request_player_authentication
      redirect_to new_player_path
    end
  end
end
