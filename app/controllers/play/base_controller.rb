module Play
  class BaseController < ActionController::Base
    include PlayerAuthentication
    skip_forgery_protection

    layout "player"

    private

    def request_player_authentication
      redirect_to new_player_path
    end
  end
end
