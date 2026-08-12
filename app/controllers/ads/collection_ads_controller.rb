module Ads
  class CollectionAdsController < ApplicationController
    before_action :set_ad, only: %i[ edit update ]

    def new
      @collection_ad = CollectionAd.new
      @ad = @collection_ad.build_ad(account: Current.account, layout: "grid")
      @ad.apply_defaults
      @available_ads = Current.account.ads.where.not(adable_type: "CollectionAd").order(:headline)
    end

    def create
      @collection_ad = CollectionAd.new(collection_ad_params)
      @ad = @collection_ad.build_ad(ad_params.merge(account: Current.account, layout: "grid"))

      if @ad.valid? & @collection_ad.valid?
        @collection_ad.save!
        redirect_to @ad, notice: t(".success")
      else
        @available_ads = Current.account.ads.where.not(adable_type: "CollectionAd").order(:headline)
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @collection_ad = @ad.adable
      @available_ads = Current.account.ads.where.not(adable_type: "CollectionAd").order(:headline)
    end

    def update
      @collection_ad = @ad.adable
      @collection_ad.assign_attributes(collection_ad_params)
      @ad.assign_attributes(ad_params.merge(layout: "grid"))

      if @ad.valid? & @collection_ad.valid?
        @collection_ad.save!
        @ad.save!
        redirect_to @ad, notice: t(".success")
      else
        @available_ads = Current.account.ads.where.not(adable_type: "CollectionAd").order(:headline)
        render :edit, status: :unprocessable_entity
      end
    end

    private

      def set_ad
        @ad = Current.account.ads.find(params[:id])
      end

      def ad_params
        params.require(:ad).permit(:headline, :body, :theme)
      end

      def collection_ad_params
        params.require(:collection_ad).permit(:collection_title, member_ad_ids: [])
      end
  end
end
