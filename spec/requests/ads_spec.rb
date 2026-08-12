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
      create(:ad, account: account, headline: "Luxury Living")
      create(:ad, headline: "Other Ad")

      get ads_path
      expect(response.body).to include("Luxury Living")
      expect(response.body).not_to include("Other Ad")
    end

    it "filters by ad type" do
      create(:ad, account: account, headline: "Listing One", adable: create(:listing_ad))
      create(:ad, account: account, headline: "Brand One", adable: create(:brand_ad))

      get ads_path, params: { ad_type: "ListingAd" }
      expect(response.body).to include("Listing One")
      expect(response.body).not_to include("Brand One")
    end
  end

  describe "GET /ads/new" do
    it "returns a successful response" do
      get new_ad_path
      expect(response).to be_successful
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
    end

    it "returns 404 for another account's ad" do
      other_ad = create(:ad)
      get preview_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
