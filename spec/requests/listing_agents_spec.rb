require "rails_helper"

RSpec.describe "ListingAgents", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:listing) { create(:listing, account: account) }
  let(:agent) { create(:agent, account: account) }

  before { sign_in(user) }

  describe "GET /listing_agents (from listing)" do
    it "returns agents for a listing" do
      create(:listing_agent, listing: listing, agent: agent)
      get listing_agents_path(listing_id: listing.id)
      expect(response).to be_successful
      expect(response.body).to include(agent.name)
    end
  end

  describe "GET /listing_agents (from agent)" do
    it "returns listings for an agent" do
      create(:listing_agent, listing: listing, agent: agent)
      get listing_agents_path(agent_id: agent.id)
      expect(response).to be_successful
      expect(response.body).to include(listing.address)
    end
  end

  describe "GET /listing_agents/new" do
    it "returns a successful response with listing context" do
      get new_listing_agent_path(listing_id: listing.id)
      expect(response).to be_successful
    end
  end

  describe "POST /listing_agents" do
    let(:valid_params) { { listing_agent: { listing_id: listing.id, agent_id: agent.id, role: "listing_agent" } } }

    context "with valid params" do
      it "creates a listing agent" do
        expect {
          post listing_agents_path, params: valid_params
        }.to change(ListingAgent, :count).by(1)
      end

      it "redirects to the listing" do
        post listing_agents_path(listing_id: listing.id), params: valid_params
        expect(response).to redirect_to(listing_path(listing))
      end
    end

    context "with invalid params" do
      it "returns 422 when agent is missing" do
        post listing_agents_path, params: { listing_agent: { listing_id: listing.id, agent_id: "", role: "listing_agent" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /listing_agents/:id/edit" do
    it "returns a successful response" do
      la = create(:listing_agent, listing: listing, agent: agent)
      get edit_listing_agent_path(la)
      expect(response).to be_successful
    end
  end

  describe "PATCH /listing_agents/:id" do
    let(:listing_agent) { create(:listing_agent, listing: listing, agent: agent, role: "listing_agent") }

    it "updates the listing agent" do
      patch listing_agent_path(listing_agent), params: { listing_agent: { role: "selling_agent" } }
      expect(listing_agent.reload.role).to eq("selling_agent")
    end

    it "redirects to the listing" do
      patch listing_agent_path(listing_agent), params: { listing_agent: { role: "selling_agent" } }
      expect(response).to redirect_to(listing_path(listing))
    end
  end

  describe "DELETE /listing_agents/:id" do
    it "destroys the listing agent" do
      la = create(:listing_agent, listing: listing, agent: agent)
      expect {
        delete listing_agent_path(la)
      }.to change(ListingAgent, :count).by(-1)
    end

    it "redirects to the listing" do
      la = create(:listing_agent, listing: listing, agent: agent)
      delete listing_agent_path(la)
      expect(response).to redirect_to(listing_path(listing))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's listing" do
      other_listing = create(:listing)
      get listing_agents_path(listing_id: other_listing.id)
      expect(response).to have_http_status(:not_found)
    end
  end
end
