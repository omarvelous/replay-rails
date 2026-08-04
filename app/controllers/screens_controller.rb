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
      redirect_to site_screen_path(@site, @screen), notice: "Screen was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @screen.update(screen_params)
      redirect_to site_screen_path(@site, @screen), notice: "Screen was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @screen.destroy
    redirect_to site_path(@site), notice: "Screen was successfully deleted."
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
      params.require(:screen).permit(:name, :orientation, playlist_ids: [])
    end
end
