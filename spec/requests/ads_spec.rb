require "rails_helper"

RSpec.describe "Ads" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  it_behaves_like "tenant isolated resource", :ad, :ad_path


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
      create(:ad, account: account, headline: "Listing Two", adable: create(:listing_ad))

      get ads_path, params: { ad_type: "Ads::ListingAd" }
      expect(response.body).to include("Listing One")
    end
  end

  describe "GET /ads/new" do
    it "redirects to new listing ad" do
      get new_ad_path
      expect(response).to redirect_to(new_ads_listing_ad_path)
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
        expect(response).to have_http_status(:unprocessable_content)
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

    it "renders the preview iframe" do
      ad = create(:ad, account: account, headline: "Test")
      get preview_ad_path(ad)
      expect(response.body).to include("iframe")
      expect(response.body).to include(ad.public_id)
    end

    it "returns ad JSON when requested as JSON" do
      listing = create(:listing, account: account)
      agent = create(:agent, account: account, name: "Jane Broker")
      create(:listing_agent, listing: listing, agent: agent, primary_at: Time.current)
      listing_ad = create(:listing_ad, listing: listing)
      ad = create(:ad, account: account, adable: listing_ad, headline: "Test")

      get preview_ad_path(ad, format: :json)
      expect(response).to be_successful
      json = response.parsed_body
      expect(json["headline"]).to eq("Test")
      expect(json["adable"]["listing"]["address"]).to eq(listing.address)
      expect(json["adable"]["agent"]["name"]).to eq("Jane Broker")
    end

    it "returns 404 for another account's ad" do
      other_ad = create(:ad)
      get preview_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
