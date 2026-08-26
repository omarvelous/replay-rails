module App
module Ads
  class ListingAdsController < App::BaseController
    before_action :set_ad, only: %i[ edit update ]

    def new
      @listing_ad = ::Ads::ListingAd.new
      @ad = @listing_ad.build_ad(account: Current.account)
      @ad.apply_defaults
      authorize @ad
    end

    def create
      @listing_ad = ::Ads::ListingAd.new(listing_ad_params)
      @ad = @listing_ad.build_ad(ad_params.merge(account: Current.account))
      authorize @ad

      if @ad.valid? & @listing_ad.valid? # non-short-circuit: validate both
        @listing_ad.save!
        redirect_to @ad, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @ad
      @listing_ad = @ad.adable
    end

    def update
      authorize @ad
      @listing_ad = @ad.adable
      @listing_ad.assign_attributes(listing_ad_params)
      @ad.assign_attributes(ad_params)

      if @listing_ad.save && @ad.save
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
        params.require(:ad).permit(:headline, :body, :layout, :theme, :image)
      end

      def listing_ad_params
        params.require(:listing_ad).permit(
          :listing_id, :badge,
          :event_date, :event_start_time, :event_end_time,
          :original_price, :sold_price, :sold_date
        )
      end
  end
end
end
