module Sites
  class ScreensController < ApplicationController
    before_action :set_site
    before_action :set_screen, only: %i[ show edit update destroy ]

    def index
      @screens = @site.screens.order(:name)
    end

    def show
    end

    def new
      @screen = @site.screens.build
    end

    def create
      @screen = @site.screens.build(screen_params)

      if @screen.save
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = "Screen was successfully created." }
          format.html { redirect_to site_screen_path(@site, @screen), notice: "Screen was successfully created." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @screen.update(screen_params)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = "Screen was successfully updated."
            render "sites/screens/create"
          end
          format.html { redirect_to site_screen_path(@site, @screen), notice: "Screen was successfully updated." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @screen.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Screen was successfully deleted."
          render "sites/screens/create"
        end
        format.html { redirect_to site_path(@site), notice: "Screen was successfully deleted." }
      end
    end

    private

      def current_account
        Current.user.account
      end

      def set_site
        @site = current_account.sites.find(params[:site_id])
      end

      def set_screen
        @screen = @site.screens.find(params[:id])
      end

      def screen_params
        params.require(:screen).permit(:name, :orientation)
      end
  end
end
