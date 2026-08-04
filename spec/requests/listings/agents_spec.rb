require "rails_helper"

RSpec.describe "Listing Agents", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:listing) { create(:listing, account: account) }
  let(:agent) { create(:agent, account: account) }

  before { sign_in(user) }

  describe "GET /listings/:listing_id/agents/new" do
    it "returns a successful response" do
      get new_listing_agent_path(listing)
      expect(response).to be_successful
    end
  end

  describe "POST /listings/:listing_id/agents" do
    let(:valid_params) { { listing_agent: { agent_id: agent.id, role: "listing_agent" } } }

    context "with valid params" do
      it "adds an agent to the listing" do
        expect {
          post listing_agents_path(listing), params: valid_params
        }.to change(listing.listing_agents, :count).by(1)
      end

      it "redirects to the listing" do
        post listing_agents_path(listing), params: valid_params
        expect(response).to redirect_to(listing_path(listing))
      end
    end

    context "with invalid params" do
      it "returns 422 when agent is missing" do
        post listing_agents_path(listing), params: { listing_agent: { agent_id: "", role: "listing_agent" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /listings/:listing_id/agents/:id/edit" do
    it "returns a successful response" do
      la = create(:listing_agent, listing: listing, agent: agent)
      get edit_listing_agent_path(listing, la)
      expect(response).to be_successful
    end
  end

  describe "PATCH /listings/:listing_id/agents/:id" do
    let(:listing_agent) { create(:listing_agent, listing: listing, agent: agent, role: "listing_agent") }

    it "updates the listing agent" do
      patch listing_agent_path(listing, listing_agent), params: { listing_agent: { role: "selling_agent" } }
      expect(listing_agent.reload.role).to eq("selling_agent")
    end

    it "redirects to the listing" do
      patch listing_agent_path(listing, listing_agent), params: { listing_agent: { role: "selling_agent" } }
      expect(response).to redirect_to(listing_path(listing))
    end
  end

  describe "DELETE /listings/:listing_id/agents/:id" do
    it "removes the agent from the listing" do
      la = create(:listing_agent, listing: listing, agent: agent)
      expect {
        delete listing_agent_path(listing, la)
      }.to change(listing.listing_agents, :count).by(-1)
    end

    it "redirects to the listing" do
      la = create(:listing_agent, listing: listing, agent: agent)
      delete listing_agent_path(listing, la)
      expect(response).to redirect_to(listing_path(listing))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's listing" do
      other_listing = create(:listing)
      get new_listing_agent_path(other_listing)
      expect(response).to have_http_status(:not_found)
    end
  end
end
