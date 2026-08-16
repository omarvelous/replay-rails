module Admin
  class PlayersController < BaseController
    def index
      @players = Player.order(created_at: :desc)
    end

    def show
      @player = Player.find(params[:id])
    end
  end
end
