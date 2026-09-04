module App
  class ListingsController < BaseController
  before_action :set_listing, only: %i[ show edit update destroy ]

  def index
    base = authorized_scope(Listing.all)
    base = base.search(params[:q]) if params[:q].present?
    base = base.by_status(params[:status]) if params[:status].present?
    @pagy, @listings = pagy(base.order(created_at: :desc))
  end

  def show
    authorize! @listing
    ad_ids = @listing.ads.pluck(:id)
    @impressions_count = ad_ids.any? ? Impression.where(ad_id: ad_ids).count : 0
    @scans_count = @listing.qr_code&.scans&.qualified&.count || 0
  end

  def new
    @listing = Current.account.listings.build(status: "active")
    authorize! @listing
  end

  def create
    @listing = Current.account.listings.build(listing_params)
    authorize! @listing

    if @listing.save
      redirect_to @listing, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! @listing
  end

  def update
    authorize! @listing
    if @listing.update(listing_params)
      redirect_to @listing, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @listing
    @listing.destroy
    redirect_to listings_path, notice: t(".success")
  end

  private

    def set_listing
      @listing = Current.account.listings.find(params[:id])
    end

    def listing_params
      params.require(:listing).permit(:address, :price, :beds, :baths, :sqft, :status, :property_type, :listing_type, :description, photos: [])
    end
  end
end
