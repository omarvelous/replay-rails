module Api
  class BaseController < ActionController::Base
    protect_from_forgery with: :null_session

    private

    def authenticate_player!
      @player = Player.find_by(token: params[:player_token] || params[:token])
      render json: { error: "Invalid player token" }, status: :unauthorized unless @player
    end
  end
end
