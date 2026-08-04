class ListingsController < ApplicationController
  before_action :set_listing, only: %i[ show edit update destroy ]

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
      redirect_to @listing, notice: "Listing was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      redirect_to @listing, notice: "Listing was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.destroy
    redirect_to listings_path, notice: "Listing was successfully deleted."
  end

  private

    def set_listing
      @listing = Current.account.listings.find(params[:id])
    end

    def listing_params
      params.require(:listing).permit(:address, :price, :beds, :baths, :sqft, :status)
    end
end
