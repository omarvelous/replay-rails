module App
  class ListingsController < BaseController
  before_action :set_listing, only: %i[ show edit update destroy ]

  def index
    base = authorized_scope(Listing.all)
    base = base.search(params[:q]) if params[:q].present?
    base = base.by_status(params[:status]) if params[:status].present?
    base = base.by_property_type(params[:property_type]) if params[:property_type].present?
    base = base.by_listing_type(params[:listing_type]) if params[:listing_type].present?
    @pagy, @listings = pagy(base.order(created_at: :desc))
  end

  def show
    authorize! @listing
    ad_pids = @listing.ads.pluck(:public_id)
    @impressions_count = if ad_pids.any?
      Analytics::Events::ContentImpressed.events
        .where("properties->>'ad_pid' IN (?)", ad_pids).count
    else
      0
    end
    @scans_count = Analytics::Events::QrScanned.events.for_destination(@listing).count
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
      @listing = Current.account.listings.find_by_param!(params[:id])
    end

    def listing_params
      params.require(:listing).permit(:address, :price, :beds, :baths, :sqft, :status, :property_type, :listing_type, :description, photos: [])
    end
  end
end
