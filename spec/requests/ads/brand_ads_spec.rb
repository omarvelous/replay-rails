require "rails_helper"

RSpec.describe "Ads::BrandAds", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /ads/brand_ads/new" do
    it "returns a successful response" do
      get new_ads_brand_ad_path
      expect(response).to be_successful
    end
  end

  describe "POST /ads/brand_ads" do
    let(:valid_params) do
      {
        ad: { headline: "Your Window, Working 24/7", body: "Digital signage for real estate.", layout: "hero", theme: "brand" },
        brand_ad: {}
      }
    end

    context "with valid params" do
      it "creates a BrandAd and Ad" do
        expect {
          post ads_brand_ads_path, params: valid_params
        }.to change(Ad, :count).by(1).and change(Ads::BrandAd, :count).by(1)
      end

      it "redirects to the ad" do
        post ads_brand_ads_path, params: valid_params
        expect(response).to redirect_to(ad_path(Ad.last))
      end
    end

    context "with invalid params" do
      it "returns 422 when headline is blank" do
        post ads_brand_ads_path, params: {
          ad: { headline: "", layout: "hero", theme: "brand" },
          brand_ad: {}
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /ads/brand_ads/:id/edit" do
    it "returns a successful response" do
      brand_ad = create(:brand_ad)
      ad = create(:ad, account: account, adable: brand_ad)
      get edit_ads_brand_ad_path(ad)
      expect(response).to be_successful
    end
  end

  describe "PATCH /ads/brand_ads/:id" do
    let(:brand_ad) { create(:brand_ad) }
    let(:ad) { create(:ad, account: account, adable: brand_ad, headline: "Old") }

    it "updates the ad" do
      patch ads_brand_ad_path(ad), params: {
        ad: { headline: "New Tagline" },
        brand_ad: {}
      }
      expect(ad.reload.headline).to eq("New Tagline")
    end

    it "redirects to the ad" do
      patch ads_brand_ad_path(ad), params: {
        ad: { headline: "New" },
        brand_ad: {}
      }
      expect(response).to redirect_to(ad_path(ad))
    end
  end

  describe "tenant isolation" do
    it "returns 404 when editing another account's ad" do
      other_ad = create(:ad, adable: create(:brand_ad))
      get edit_ads_brand_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
