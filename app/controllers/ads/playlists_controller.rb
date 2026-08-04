module Ads
  class PlaylistsController < ApplicationController
    before_action :set_ad
    before_action :set_playlist_ad, only: %i[ destroy ]

    def index
      @playlist_ads = @ad.playlist_ads.includes(:playlist)
    end

    def destroy
      @playlist_ad.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Ad was removed from the playlist."
        end
        format.html { redirect_to @ad, notice: "Ad was removed from the playlist." }
      end
    end

    private

      def current_account
        Current.user.account
      end

      def set_ad
        @ad = current_account.ads.find(params[:ad_id])
      end

      def set_playlist_ad
        @playlist_ad = @ad.playlist_ads.find(params[:id])
      end
  end
end
