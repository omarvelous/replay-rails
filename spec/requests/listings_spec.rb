require "rails_helper"

RSpec.describe "Listings" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /listings" do
    it "returns a successful response" do
      get listings_path
      expect(response).to be_successful
    end

    it "lists listings for the current account" do
      listing = create(:listing, account: account, address: "123 Main St")
      other_listing = create(:listing, address: "999 Other Ave")

      get listings_path
      expect(response.body).to include("123 Main St")
      expect(response.body).not_to include("999 Other Ave")
    end
  end

  describe "GET /listings/new" do
    it "returns a successful response" do
      get new_listing_path
      expect(response).to be_successful
    end
  end

  describe "POST /listings" do
    let(:valid_params) do
      { listing: { address: "100 Park Ave", price: 750_000, beds: 3, baths: 2, sqft: 1800, status: "active" } }
    end

    context "with valid params" do
      it "creates a listing scoped to the current account" do
        expect {
          post listings_path, params: valid_params
        }.to change(account.listings, :count).by(1)
      end

      it "redirects to the listing" do
        post listings_path, params: valid_params
        expect(response).to redirect_to(listing_path(Listing.last))
      end

      it "attaches photos when provided" do
        params = valid_params.deep_merge(listing: { photos: [ fixture_file_upload("test.jpg", "image/jpeg") ] })
        post listings_path, params: params
        expect(Listing.last.photos).to be_attached
      end
    end

    context "with invalid params" do
      it "does not create a listing" do
        expect {
          post listings_path, params: { listing: { address: "" } }
        }.not_to change(Listing, :count)
      end

      it "returns 422" do
        post listings_path, params: { listing: { address: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /listings/:id" do
    it "shows the listing" do
      listing = create(:listing, account: account, address: "123 Main St")
      get listing_path(listing)
      expect(response).to be_successful
      expect(response.body).to include("123 Main St")
    end

    it "returns 404 for another account's listing" do
      other_listing = create(:listing)
      get listing_path(other_listing)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /listings/:id/edit" do
    it "returns a successful response" do
      listing = create(:listing, account: account)
      get edit_listing_path(listing)
      expect(response).to be_successful
    end
  end

  describe "PATCH /listings/:id" do
    let(:listing) { create(:listing, account: account, address: "Old Address") }

    context "with valid params" do
      it "updates the listing" do
        patch listing_path(listing), params: { listing: { address: "New Address" } }
        expect(listing.reload.address).to eq("New Address")
      end

      it "redirects to the listing" do
        patch listing_path(listing), params: { listing: { address: "New Address" } }
        expect(response).to redirect_to(listing_path(listing))
      end
    end

    context "with invalid params" do
      it "returns 422" do
        patch listing_path(listing), params: { listing: { address: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /listings/:id" do
    it "destroys the listing" do
      listing = create(:listing, account: account)
      expect {
        delete listing_path(listing)
      }.to change(account.listings, :count).by(-1)
    end

    it "redirects to the index" do
      listing = create(:listing, account: account)
      delete listing_path(listing)
      expect(response).to redirect_to(listings_path)
    end
  end
end
