module Play
  class BaseController < ActionController::Base
    include PlayerAuthentication
    skip_forgery_protection

    private

    def request_player_authentication
      head :unauthorized
    end
  end
end
