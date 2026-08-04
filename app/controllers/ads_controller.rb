class AdsController < ApplicationController
  before_action :set_ad, only: %i[ show edit update destroy preview ]

  def index
    @ads = current_account.ads.order(created_at: :desc)
  end

  def show
  end

  def new
    @ad = current_account.ads.build
  end

  def create
    @ad = current_account.ads.build(ad_params)

    if @ad.save
      redirect_to @ad, notice: "Ad was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @ad.update(ad_params)
      redirect_to @ad, notice: "Ad was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    render layout: "preview"
  end

  def destroy
    @ad.destroy
    redirect_to ads_path, notice: "Ad was successfully deleted."
  end

  private

    def current_account
      Current.user.account
    end

    def set_ad
      @ad = current_account.ads.find(params[:id])
    end

    def ad_params
      params.require(:ad).permit(:headline, :body, :listing_id)
    end
end
