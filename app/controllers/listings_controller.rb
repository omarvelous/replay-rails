class ListingsController < ApplicationController
  before_action :set_listing, only: %i[ show edit update destroy ads ]

  def index
    @listings = Current.account.listings.order(created_at: :desc)
  end

  def show
  end

  def new
    @listing = Current.account.listings.build(status: "active")
  end

  def create
    @listing = Current.account.listings.build(listing_params)

    if @listing.save
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @listing, notice: t(".success") }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = t(".success") }
        format.html { redirect_to @listing, notice: t(".success") }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.destroy
    redirect_to listings_path, notice: t(".success")
  end

  def ads
    @ads = @listing.ads
  end

  private

    def set_listing
      @listing = Current.account.listings.find(params[:id])
    end

    def listing_params
      params.require(:listing).permit(:address, :price, :beds, :baths, :sqft, :status)
    end
end
