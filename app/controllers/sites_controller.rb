class SitesController < ApplicationController
  before_action :set_site, only: %i[ show edit update destroy ]

  def index
    @sites = current_account.sites.order(:name)
  end

  def show
  end

  def new
    @site = current_account.sites.build
  end

  def create
    @site = current_account.sites.build(site_params)

    if @site.save
      redirect_to @site, notice: "Site was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @site.update(site_params)
      redirect_to @site, notice: "Site was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @site.destroy
    redirect_to sites_path, notice: "Site was successfully deleted."
  end

  private

    def set_site
      @site = current_account.sites.find(params[:id])
    end

    def site_params
      params.require(:site).permit(:name, :address)
    end
end
