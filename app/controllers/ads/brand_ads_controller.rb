module Ads
  class BrandAdsController < ApplicationController
    before_action :set_ad, only: %i[ edit update ]

    def new
      @brand_ad = BrandAd.new
      @ad = @brand_ad.build_ad(account: Current.account)
      @ad.apply_defaults
    end

    def create
      @brand_ad = BrandAd.new
      @ad = @brand_ad.build_ad(ad_params.merge(account: Current.account))

      if @ad.valid? & @brand_ad.valid?
        @brand_ad.save!
        redirect_to @ad, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @brand_ad = @ad.adable
    end

    def update
      @brand_ad = @ad.adable
      @ad.assign_attributes(ad_params)

      if @ad.valid?
        @ad.save!
        redirect_to @ad, notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def set_ad
        @ad = Current.account.ads.find(params[:id])
      end

      def ad_params
        params.require(:ad).permit(:headline, :body, :layout, :theme)
      end
  end
end
