require "rails_helper"

RSpec.describe "Ads::ListingAds" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:listing) { create(:listing, account: account) }

  before { sign_in(user) }

  describe "GET /ads/listing_ads/new" do
    it "returns a successful response" do
      get new_ads_listing_ad_path
      expect(response).to be_successful
    end
  end

  describe "POST /ads/listing_ads" do
    let(:valid_params) do
      {
        ad: { headline: "Just Listed on Fifth", body: "Beautiful property.", layout: "hero", theme: "dark" },
        listing_ad: { listing_id: listing.id, badge: "just_listed" }
      }
    end

    context "with valid params" do
      it "creates a ListingAd and Ad" do
        expect {
          post ads_listing_ads_path, params: valid_params
        }.to change(Ad, :count).by(1).and change(Ads::ListingAd, :count).by(1)
      end

      it "scopes the ad to the current account" do
        post ads_listing_ads_path, params: valid_params
        expect(Ad.last.account).to eq(account)
      end

      it "redirects to the ad" do
        post ads_listing_ads_path, params: valid_params
        expect(response).to redirect_to(ad_path(Ad.last))
      end

      it "creates an open_house with event fields" do
        params = {
          ad: { headline: "Open House", layout: "hero", theme: "dark" },
          listing_ad: {
            listing_id: listing.id, badge: "open_house",
            event_date: 1.week.from_now.to_date,
            event_start_time: "13:00", event_end_time: "15:00"
          }
        }
        post ads_listing_ads_path, params: params
        expect(Ad.last.adable).to be_open_house
        expect(Ad.last.adable.event_date).to eq(1.week.from_now.to_date)
      end

      it "attaches an image when provided" do
        params = valid_params.deep_merge(ad: { image: fixture_file_upload("test.jpg", "image/jpeg") })
        post ads_listing_ads_path, params: params
        expect(Ad.last.image).to be_attached
      end
    end

    context "with invalid params" do
      it "returns 422 when headline is blank" do
        post ads_listing_ads_path, params: {
          ad: { headline: "", layout: "hero", theme: "dark" },
          listing_ad: { listing_id: listing.id, badge: "just_listed" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns 422 when listing is missing" do
        post ads_listing_ads_path, params: {
          ad: { headline: "Test", layout: "hero", theme: "dark" },
          listing_ad: { listing_id: "", badge: "just_listed" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /ads/listing_ads/:id/edit" do
    it "returns a successful response" do
      listing_ad = create(:listing_ad, listing: listing)
      ad = create(:ad, account: account, adable: listing_ad)
      get edit_ads_listing_ad_path(ad)
      expect(response).to be_successful
    end
  end

  describe "PATCH /ads/listing_ads/:id" do
    let(:listing_ad) { create(:listing_ad, listing: listing) }
    let(:ad) { create(:ad, account: account, adable: listing_ad, headline: "Old") }

    it "updates the ad and listing_ad" do
      patch ads_listing_ad_path(ad), params: {
        ad: { headline: "Updated Headline" },
        listing_ad: { badge: "coming_soon" }
      }
      ad.reload
      expect(ad.headline).to eq("Updated Headline")
      expect(ad.adable.badge).to eq("coming_soon")
    end

    it "redirects to the ad" do
      patch ads_listing_ad_path(ad), params: {
        ad: { headline: "Updated" },
        listing_ad: { badge: "just_listed" }
      }
      expect(response).to redirect_to(ad_path(ad))
    end

    it "returns 422 with invalid params" do
      patch ads_listing_ad_path(ad), params: {
        ad: { headline: "" },
        listing_ad: { badge: "just_listed" }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "tenant isolation" do
    it "returns 404 when editing another account's ad" do
      other_ad = create(:ad)
      get edit_ads_listing_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 when updating another account's ad" do
      other_ad = create(:ad)
      patch ads_listing_ad_path(other_ad), params: {
        ad: { headline: "Hacked" },
        listing_ad: { badge: "just_listed" }
      }
      expect(response).to have_http_status(:not_found)
    end
  end
end
