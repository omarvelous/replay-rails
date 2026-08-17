require "rails_helper"

RSpec.describe "Ads::CollectionAds" do
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
    let(:first_listing) { create(:listing, account: account) }
    let(:second_listing) { create(:listing, account: account) }
    let!(:first_ad) { create(:ad, account: account, adable: create(:listing_ad, listing: first_listing)) }
    let!(:second_ad) { create(:ad, account: account, adable: create(:listing_ad, listing: second_listing)) }

    let(:valid_params) do
      {
        ad: { headline: "Open Houses This Weekend", layout: "grid", theme: "dark" },
        collection_ad: { collection_title: "Open Houses This Weekend", member_ad_ids: [ first_ad.id, second_ad.id ] }
      }
    end

    context "with valid params" do
      it "creates a CollectionAd and Ad" do
        expect {
          post ads_collection_ads_path, params: valid_params
        }.to change(Ad, :count).by(1).and change(Ads::CollectionAd, :count).by(1)
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
        expect(response).to have_http_status(:unprocessable_content)
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

  describe "tenant isolation" do
    it "returns 404 when editing another account's ad" do
      other_ad = create(:ad, adable: create(:collection_ad), layout: "grid")
      get edit_ads_collection_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
