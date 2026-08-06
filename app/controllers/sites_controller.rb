class SitesController < ApplicationController
  before_action :set_site, only: %i[ show edit update destroy screens ]

  def index
    @sites = Current.account.sites.order(:name)
  end

  def show
  end

  def new
    @site = Current.account.sites.build
  end

  def create
    @site = Current.account.sites.build(site_params)

    if @site.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @site, notice: t(".success") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @site, notice: t(".success") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, notice: t(".success")
  end

  def screens
    @screens = @site.screens.includes(screen_playlists: :playlist).order(:name)
  end

  private

    def set_site
      @site = Current.account.sites.find(params[:id])
    end

    def site_params
      params.require(:site).permit(:name, :address)
    end
end
