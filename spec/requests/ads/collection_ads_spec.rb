require "rails_helper"

RSpec.describe "Ads::CollectionAds", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /ads/collection_ads/new" do
    it "returns a successful response" do
      get new_ads_collection_ad_path
      expect(response).to be_successful
    end
  end

  describe "POST /ads/collection_ads" do
    let(:listing1) { create(:listing, account: account) }
    let(:listing2) { create(:listing, account: account) }
    let!(:ad1) { create(:ad, account: account, adable: create(:listing_ad, listing: listing1)) }
    let!(:ad2) { create(:ad, account: account, adable: create(:listing_ad, listing: listing2)) }

    let(:valid_params) do
      {
        ad: { headline: "Open Houses This Weekend", layout: "grid", theme: "dark" },
        collection_ad: { collection_title: "Open Houses This Weekend", member_ad_ids: [ ad1.id, ad2.id ] }
      }
    end

    context "with valid params" do
      it "creates a CollectionAd and Ad" do
        expect {
          post ads_collection_ads_path, params: valid_params
        }.to change(Ad, :count).by(1).and change(CollectionAd, :count).by(1)
      end

      it "redirects to the ad" do
        post ads_collection_ads_path, params: valid_params
        expect(response).to redirect_to(ad_path(Ad.last))
      end
    end

    context "with invalid params" do
      it "returns 422 when collection_title is blank" do
        post ads_collection_ads_path, params: {
          ad: { headline: "Test", layout: "grid", theme: "dark" },
          collection_ad: { collection_title: "" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /ads/collection_ads/:id/edit" do
    it "returns a successful response" do
      collection_ad = create(:collection_ad, collection_title: "Test Collection")
      ad = create(:ad, account: account, adable: collection_ad, layout: "grid")
      get edit_ads_collection_ad_path(ad)
      expect(response).to be_successful
    end
  end

  describe "PATCH /ads/collection_ads/:id" do
    let(:collection_ad) { create(:collection_ad, collection_title: "Old Title") }
    let(:ad) { create(:ad, account: account, adable: collection_ad, headline: "Old", layout: "grid") }

    it "updates the ad and collection_ad" do
      patch ads_collection_ad_path(ad), params: {
        ad: { headline: "Updated" },
        collection_ad: { collection_title: "New Title" }
      }
      ad.reload
      expect(ad.headline).to eq("Updated")
      expect(ad.adable.collection_title).to eq("New Title")
    end

    it "redirects to the ad" do
      patch ads_collection_ad_path(ad), params: {
        ad: { headline: "Updated" },
        collection_ad: { collection_title: "New Title" }
      }
      expect(response).to redirect_to(ad_path(ad))
    end
  end
end
