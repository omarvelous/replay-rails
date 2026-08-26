module App
  class AdsController < BaseController
  before_action :set_ad, only: %i[ show edit update destroy preview ]

  def index
    base = authorized_scope(Ad.all)
    base = base.search(params[:q]) if params[:q].present?
    base = base.where(adable_type: params[:ad_type]) if params[:ad_type].present?
    @pagy, @ads = pagy(base.order(created_at: :desc))
  end

  def show
    authorize! @ad
    @playlists = @ad.playlists.distinct
    @scan_count = QrScan.qualified.where(ad: @ad).count
  end

  def new
    authorize! Ad
    # Renders type chooser — links to ads/listing_ads/new, etc.
  end

  def edit
    authorize! @ad
  end

  def update
    authorize! @ad
    if @ad.update(ad_params)
      redirect_to @ad, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    authorize! @ad, to: :show?
    render layout: "preview"
  end

  def destroy
    authorize! @ad
    @ad.destroy
    redirect_to ads_path, notice: t(".success")
  end

  private

    def set_ad
      @ad = Current.account.ads.find(params[:id])
    end

    def ad_params
      params.require(:ad).permit(:headline, :body, :layout, :theme, :image)
    end
  end
end
