module App
  class SitesController < BaseController
  before_action :set_site, only: %i[ show edit update destroy ]

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
      redirect_to @site, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
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
