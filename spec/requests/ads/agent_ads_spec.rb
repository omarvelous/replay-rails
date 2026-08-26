require "rails_helper"

RSpec.describe "Ads::AgentAds" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:agent) { create(:agent, account: account) }

  before { sign_in(user) }

  describe "GET /ads/agent_ads/new" do
    it "returns a successful response" do
      get new_ads_agent_ad_path
      expect(response).to be_successful
    end
  end

  describe "POST /ads/agent_ads" do
    let(:valid_params) do
      {
        ad: { headline: "Meet Sarah", body: "Your trusted advisor.", layout: "profile", theme: "dark" },
        agent_ad: { agent_id: agent.id }
      }
    end

    context "with valid params" do
      it "creates an AgentAd and Ad" do
        expect {
          post ads_agent_ads_path, params: valid_params
        }.to change(Ad, :count).by(1).and change(Ads::AgentAd, :count).by(1)
      end

      it "redirects to the ad" do
        post ads_agent_ads_path, params: valid_params
        expect(response).to redirect_to(ad_path(Ad.last))
      end
    end

    context "with invalid params" do
      it "returns 422 when agent is missing" do
        post ads_agent_ads_path, params: {
          ad: { headline: "Test", layout: "profile", theme: "dark" },
          agent_ad: { agent_id: "" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /ads/agent_ads/:id/edit" do
    it "returns a successful response" do
      agent_ad = create(:agent_ad, agent: agent)
      ad = create(:ad, account: account, adable: agent_ad, layout: "profile")
      get edit_ads_agent_ad_path(ad)
      expect(response).to be_successful
    end
  end

  describe "PATCH /ads/agent_ads/:id" do
    let(:agent_ad) { create(:agent_ad, agent: agent) }
    let(:ad) { create(:ad, account: account, adable: agent_ad, headline: "Old", layout: "profile") }

    it "updates the ad" do
      patch ads_agent_ad_path(ad), params: {
        ad: { headline: "Updated" },
        agent_ad: { agent_id: agent.id }
      }
      expect(ad.reload.headline).to eq("Updated")
    end

    it "redirects to the ad" do
      patch ads_agent_ad_path(ad), params: {
        ad: { headline: "Updated" },
        agent_ad: { agent_id: agent.id }
      }
      expect(response).to redirect_to(ad_path(ad))
    end
  end

  describe "tenant isolation" do
    it "returns 404 when editing another account's ad" do
      other_ad = create(:ad, adable: create(:agent_ad), layout: "profile")
      get edit_ads_agent_ad_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
