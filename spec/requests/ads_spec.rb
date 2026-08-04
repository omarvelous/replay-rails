require "rails_helper"

RSpec.describe "Ads", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /ads" do
    it "returns a successful response" do
      get ads_path
      expect(response).to be_successful
    end

    it "lists ads for the current account" do
      ad = create(:ad, account: account, headline: "Luxury Living")
      other_ad = create(:ad, headline: "Other Ad")

      get ads_path
      expect(response.body).to include("Luxury Living")
      expect(response.body).not_to include("Other Ad")
    end
  end

  describe "GET /ads/new" do
    it "returns a successful response" do
      get new_ad_path
      expect(response).to be_successful
    end
  end

  describe "POST /ads" do
    let(:valid_params) do
      { ad: { headline: "Dream Home Awaits", body: "Schedule a showing today." } }
    end

    context "with valid params" do
      it "creates an ad scoped to the current account" do
        expect {
          post ads_path, params: valid_params
        }.to change(account.ads, :count).by(1)
      end

      it "redirects to the ad" do
        post ads_path, params: valid_params
        expect(response).to redirect_to(ad_path(Ad.last))
      end
    end

    context "with a linked listing" do
      it "associates the ad with a listing" do
        listing = create(:listing, account: account)
        post ads_path, params: valid_params.deep_merge(ad: { listing_id: listing.id })
        expect(Ad.last.listing).to eq(listing)
      end
    end

    context "with invalid params" do
      it "does not create an ad" do
        expect {
          post ads_path, params: { ad: { headline: "" } }
        }.not_to change(Ad, :count)
      end

      it "returns 422" do
        post ads_path, params: { ad: { headline: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /ads/:id" do
    it "shows the ad" do
      ad = create(:ad, account: account, headline: "Luxury Living")
      get ad_path(ad)
      expect(response).to be_successful
      expect(response.body).to include("Luxury Living")
    end

    it "returns 404 for another account's ad" do
      other_ad = create(:ad)
      get ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /ads/:id/edit" do
    it "returns a successful response" do
      ad = create(:ad, account: account)
      get edit_ad_path(ad)
      expect(response).to be_successful
    end
  end

  describe "PATCH /ads/:id" do
    let(:ad) { create(:ad, account: account, headline: "Old Headline") }

    context "with valid params" do
      it "updates the ad" do
        patch ad_path(ad), params: { ad: { headline: "New Headline" } }
        expect(ad.reload.headline).to eq("New Headline")
      end

      it "redirects to the ad" do
        patch ad_path(ad), params: { ad: { headline: "New Headline" } }
        expect(response).to redirect_to(ad_path(ad))
      end
    end

    context "with invalid params" do
      it "returns 422" do
        patch ad_path(ad), params: { ad: { headline: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /ads/:id" do
    it "destroys the ad" do
      ad = create(:ad, account: account)
      expect {
        delete ad_path(ad)
      }.to change(account.ads, :count).by(-1)
    end

    it "redirects to the index" do
      ad = create(:ad, account: account)
      delete ad_path(ad)
      expect(response).to redirect_to(ads_path)
    end
  end

  describe "GET /ads/:id/preview" do
    it "returns a successful response" do
      ad = create(:ad, account: account, headline: "Preview Me")
      get preview_ad_path(ad)
      expect(response).to be_successful
      expect(response.body).to include("Preview Me")
    end

    it "includes listing details when linked" do
      listing = create(:listing, account: account, address: "123 Main St")
      ad = create(:ad, account: account, listing: listing)
      get preview_ad_path(ad)
      expect(response.body).to include("123 Main St")
    end

    it "includes agent info from linked listing" do
      listing = create(:listing, account: account)
      agent = create(:agent, account: account, name: "Jane Broker")
      create(:listing_agent, listing: listing, agent: agent)
      ad = create(:ad, account: account, listing: listing)

      get preview_ad_path(ad)
      expect(response.body).to include("Jane Broker")
    end

    it "returns 404 for another account's ad" do
      other_ad = create(:ad)
      get preview_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
