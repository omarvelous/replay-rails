class PlaylistAdsController < ApplicationController
  before_action :set_playlist_ad, only: %i[ edit update destroy ]

  def index
    raise ActiveRecord::RecordNotFound unless scope
    @playlist_ads = scope.includes(:playlist, :ad)
  end

  def new
    next_position = current_playlist ? (current_playlist.playlist_ads.maximum(:position) || 0) + 1 : 1
    @playlist_ad = PlaylistAd.new(
      playlist_id: current_playlist&.id,
      ad_id: current_ad&.id,
      position: next_position,
      duration: 10
    )
  end

  def create
    @playlist_ad = PlaylistAd.new(playlist_ad_params)

    if valid_tenant?(@playlist_ad) && @playlist_ad.save
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Ad and playlist linked."
          @playlist_ads = scope.includes(:playlist, :ad)
        end
        format.html { redirect_to redirect_target, notice: "Ad and playlist linked." }
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
          @playlist_ads = scope.includes(:playlist, :ad)
          render "playlist_ads/create"
        end
        format.html { redirect_to redirect_target, notice: "Playlist ad was updated." }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist_ad.destroy
    respond_to do |format|
      format.turbo_stream do
        flash.now[:notice] = "Ad and playlist unlinked."
        @playlist_ads = scope.includes(:playlist, :ad)
        render "playlist_ads/create"
      end
      format.html { redirect_to redirect_target, notice: "Ad and playlist unlinked." }
    end
  end

  private

    def current_account
      Current.user.account
    end

    def current_playlist
      @current_playlist ||= current_account.playlists.find_by(id: params[:playlist_id])
    end
    helper_method :current_playlist

    def current_ad
      @current_ad ||= current_account.ads.find_by(id: params[:ad_id])
    end
    helper_method :current_ad

    def scope
      if current_playlist
        current_playlist.playlist_ads
      elsif current_ad
        current_ad.playlist_ads
      end
    end

    def set_playlist_ad
      @playlist_ad = PlaylistAd.joins(playlist: :account).find_by!(
        id: params[:id],
        accounts: { id: current_account.id }
      )
      @current_playlist = @playlist_ad.playlist
      @current_ad = @playlist_ad.ad
    end

    def valid_tenant?(playlist_ad)
      playlist_ad.playlist_id.present? &&
        playlist_ad.ad_id.present? &&
        current_account.playlists.exists?(playlist_ad.playlist_id) &&
        current_account.ads.exists?(playlist_ad.ad_id)
    end

    def redirect_target
      current_playlist || current_ad || @playlist_ad&.playlist
    end

    def playlist_ad_params
      params.require(:playlist_ad).permit(:playlist_id, :ad_id, :position, :duration)
    end
end
