module App
  class SitesController < BaseController
  before_action :set_site, only: %i[ show edit update destroy ]

  def index
    @sites = authorized_scope(Site.all).order(:name)
  end

  def show
    authorize! @site
  end

  def new
    @site = Current.account.sites.build
    authorize! @site
  end

  def create
    @site = Current.account.sites.build(site_params)
    authorize! @site

    if @site.save
      redirect_to @site, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! @site
  end

  def update
    authorize! @site
    if @site.update(site_params)
      redirect_to @site, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @site
    @site.destroy
    redirect_to sites_path, notice: t(".success")
  end

  private

    def set_site
      @site = Current.account.sites.find(params[:id])
    end

    def site_params
      params.require(:site).permit(:name, :address, :photo)
    end
  end
end
