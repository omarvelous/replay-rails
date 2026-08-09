class PlaylistAdsController < ApplicationController
  before_action :set_playlist
  before_action :set_playlist_ad, only: %i[ edit update destroy ]

  def new
    @playlist_ad = @playlist.playlist_ads.build(duration: 10)
  end

  def create
    @playlist_ad = @playlist.playlist_ads.build(playlist_ad_params)

    if @playlist_ad.save
      redirect_to @playlist, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @playlist_ad.update(playlist_ad_params)
      redirect_to @playlist, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist_ad.destroy
    redirect_to @playlist, notice: t(".success")
  end

  private

    def set_playlist
      @playlist = Current.account.playlists.find(params[:playlist_id])
    end

    def set_playlist_ad
      @playlist_ad = @playlist.playlist_ads.find(params[:id])
    end

    def playlist_ad_params
      params.require(:playlist_ad).permit(:ad_id, :position, :duration)
    end
end
