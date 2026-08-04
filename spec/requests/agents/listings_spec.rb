require "rails_helper"

RSpec.describe "Agent Listings", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:agent) { create(:agent, account: account) }
  let(:listing) { create(:listing, account: account) }

  before { sign_in(user) }

  describe "GET /agents/:agent_id/listings" do
    it "returns a successful response" do
      get agent_listings_path(agent)
      expect(response).to be_successful
    end

    it "lists listings for the agent" do
      create(:listing_agent, agent: agent, listing: listing)
      get agent_listings_path(agent)
      expect(response.body).to include(listing.address)
    end
  end

  describe "DELETE /agents/:agent_id/listings/:id" do
    it "removes the listing from the agent" do
      la = create(:listing_agent, agent: agent, listing: listing)
      expect {
        delete agent_listing_path(agent, la)
      }.to change(agent.listing_agents, :count).by(-1)
    end

    it "redirects to the agent" do
      la = create(:listing_agent, agent: agent, listing: listing)
      delete agent_listing_path(agent, la)
      expect(response).to redirect_to(agent_path(agent))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's agent" do
      other_agent = create(:agent)
      get agent_listings_path(other_agent)
      expect(response).to have_http_status(:not_found)
    end
  end
end
