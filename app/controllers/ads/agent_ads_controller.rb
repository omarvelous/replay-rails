module Ads
  class AgentAdsController < ApplicationController
    before_action :set_ad, only: %i[ edit update ]

    def new
      @agent_ad = AgentAd.new
      @ad = @agent_ad.build_ad(account: Current.account)
      @ad.apply_defaults
    end

    def create
      @agent_ad = AgentAd.new(agent_ad_params)
      @ad = @agent_ad.build_ad(ad_params.merge(account: Current.account))

      if @ad.valid? & @agent_ad.valid?
        @agent_ad.save!
        redirect_to @ad, notice: t(".success")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @agent_ad = @ad.adable
    end

    def update
      @agent_ad = @ad.adable
      @agent_ad.assign_attributes(agent_ad_params)
      @ad.assign_attributes(ad_params)

      if @ad.valid? & @agent_ad.valid?
        @agent_ad.save!
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
        params.require(:ad).permit(:headline, :body, :layout, :theme, :image)
      end

      def agent_ad_params
        params.require(:agent_ad).permit(:agent_id)
      end
  end
end
