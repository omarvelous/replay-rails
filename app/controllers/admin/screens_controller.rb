module Admin
  class ScreensController < BaseController
    def index
      @screens = Screen.includes(site: :account).order(created_at: :desc)
    end

    def show
      @screen = Screen.find(params[:id])
    end
  end
end
