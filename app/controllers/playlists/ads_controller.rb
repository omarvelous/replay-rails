module Playlists
  class AdsController < ApplicationController
    before_action :set_playlist
    before_action :set_playlist_ad, only: %i[ edit update destroy ]

    def index
      @playlist_ads = @playlist.playlist_ads.includes(:ad)
    end

    def new
      next_position = (@playlist.playlist_ads.maximum(:position) || 0) + 1
      @playlist_ad = @playlist.playlist_ads.build(position: next_position, duration: 10)
    end

    def create
      @playlist_ad = @playlist.playlist_ads.build(playlist_ad_params)

      if @playlist_ad.save
        respond_to do |format|
          format.turbo_stream { flash.now[:notice] = "Ad was added to the playlist." }
          format.html { redirect_to @playlist, notice: "Ad was added to the playlist." }
        end
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @playlist_ad.update(playlist_ad_params)
        respond_to do |format|
          format.turbo_stream do
            flash.now[:notice] = "Playlist ad was updated."
            render "playlists/ads/create"
          end
          format.html { redirect_to @playlist, notice: "Playlist ad was updated." }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @playlist_ad.destroy
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Ad was removed from the playlist."
          render "playlists/ads/create"
        end
        format.html { redirect_to @playlist, notice: "Ad was removed from the playlist." }
      end
    end

    private

      def current_account
        Current.user.account
      end

      def set_playlist
        @playlist = current_account.playlists.find(params[:playlist_id])
      end

      def set_playlist_ad
        @playlist_ad = @playlist.playlist_ads.find(params[:id])
      end

      def playlist_ad_params
        params.require(:playlist_ad).permit(:ad_id, :position, :duration)
      end
  end
end
