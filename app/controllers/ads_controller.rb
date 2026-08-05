class AdsController < ApplicationController
  before_action :set_ad, only: %i[ show edit update destroy preview playlists ]

  def index
    @ads = Current.account.ads.order(created_at: :desc)
  end

  def show
  end

  def new
    @ad = Current.account.ads.build
  end

  def create
    @ad = Current.account.ads.build(ad_params)

    if @ad.save
      redirect_to @ad, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ad.update(ad_params)
      redirect_to @ad, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    render layout: "preview"
  end

  def playlists
    @playlists = @ad.playlists.distinct
  end

  def destroy
    @ad.destroy
    redirect_to ads_path, notice: t(".success")
  end

  private

    def set_ad
      @ad = Current.account.ads.find(params[:id])
    end

    def ad_params
      params.require(:ad).permit(:headline, :body, :listing_id)
    end
end
