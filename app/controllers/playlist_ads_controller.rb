class PlaylistAdsController < ApplicationController
  before_action :set_playlist
  before_action :set_playlist_ad, only: %i[ edit update destroy ]

  def index
    @playlist_ads = @playlist.playlist_ads.includes(:ad)
  end

  def timeline
    @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
  end

  def new
    @playlist_ad = @playlist.playlist_ads.build(duration: 10)
  end

  def create
    @playlist_ad = @playlist.playlist_ads.build(playlist_ad_params)

    if @playlist_ad.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @playlist, notice: t(".success") }
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
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @playlist, notice: t(".success") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist_ad.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t(".success") }
      format.html { redirect_to @playlist, notice: t(".success") }
    end
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
