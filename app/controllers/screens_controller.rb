class ScreensController < ApplicationController
  before_action :set_screen, only: %i[ show edit update destroy ]

  def index
    base = scope.includes(:site, screen_playlists: :playlist)
    base = base.search(params[:q]) if params[:q].present?
    base = base.live   if params[:status] == "live"
    base = base.idle   if params[:status] == "idle"
    @pagy, @screens = pagy(base.order(:name))
  end

  def show
  end

  def new
    @screen = scope.build
  end

  def create
    @site = Current.account.sites.find(params[:screen][:site_id])
    @screen = @site.screens.build(screen_params)

    if @screen.save
      redirect_to @screen, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @screen.update(screen_params)
      redirect_to @screen, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    site = @screen.site
    @screen.destroy
    redirect_to site_path(site), notice: t(".success")
  end

  private

    def current_site
      @current_site ||= Current.account.sites.find(params[:site_id]) if params[:site_id]
    end
    helper_method :current_site

    def scope
      current_site&.screens || Current.account.screens
    end

    def set_screen
      @screen = Current.account.screens.find(params[:id])
      @site = @screen.site
    end

    def screen_params
      params.require(:screen).permit(:name, :orientation)
    end
end
