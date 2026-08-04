module Sites
  class ScreensController < ApplicationController
    before_action :set_site

    def index
      @screens = @site.screens.order(:name)
    end

    def new
      @screen = @site.screens.build
    end

    def create
      @screen = @site.screens.build(screen_params)

      if @screen.save
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = "Screen was successfully created." }
          format.html { redirect_to screen_path(@screen), notice: "Screen was successfully created." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

      def current_account
        Current.user.account
      end

      def set_site
        @site = current_account.sites.find(params[:site_id])
      end

      def screen_params
        params.require(:screen).permit(:name, :orientation)
      end
  end
end
