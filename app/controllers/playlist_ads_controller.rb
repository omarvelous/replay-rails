class PlaylistAdsController < ApplicationController
  before_action :set_playlist_ad, only: %i[ edit update destroy ]

  def index
    @playlist_ads = parent.playlist_ads.includes(:playlist, :ad)
  end

  def new
    @playlist_ad = parent.playlist_ads.build(duration: 10)
  end

  def create
    @playlist_ad = parent.playlist_ads.build(playlist_ad_params)

    if @playlist_ad.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to parent, notice: t(".success") }
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
        format.html { redirect_to parent, notice: t(".success") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist_ad.destroy
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t(".success") }
      format.html { redirect_to parent, notice: t(".success") }
    end
  end

  private

    def parent
      raise NotImplementedError
    end
    helper_method :parent

    def set_playlist_ad
      @playlist_ad = Current.account.playlist_ads.find(params[:id])
    end

    def playlist_ad_params
      params.require(:playlist_ad).permit(:playlist_id, :ad_id, :position, :duration)
    end
end
