require "rails_helper"

RSpec.describe "ListingAgents", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:listing) { create(:listing, account: account) }
  let(:agent) { create(:agent, account: account) }

  before { sign_in(user) }

  describe "from listing context" do
    describe "GET /listings/:id/listing_agents/new" do
      it "returns a successful response" do
        get new_listing_listing_agent_path(listing)
        expect(response).to be_successful
      end
    end

    describe "POST /listings/:id/listing_agents" do
      it "creates a listing agent" do
        expect {
          post listing_listing_agents_path(listing), params: { listing_agent: { agent_id: agent.id, role: "listing_agent" } }
        }.to change(ListingAgent, :count).by(1)
      end

      it "redirects to the listing" do
        post listing_listing_agents_path(listing), params: { listing_agent: { agent_id: agent.id, role: "listing_agent" } }
        expect(response).to redirect_to(listing_path(listing))
      end

      it "returns 422 when agent is missing" do
        post listing_listing_agents_path(listing), params: { listing_agent: { agent_id: "", role: "listing_agent" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /listings/:id/listing_agents/:id/edit" do
      it "returns a successful response" do
        la = create(:listing_agent, listing: listing, agent: agent)
        get edit_listing_listing_agent_path(listing, la)
        expect(response).to be_successful
      end
    end

    describe "PATCH /listings/:id/listing_agents/:id" do
      it "updates the listing agent" do
        la = create(:listing_agent, listing: listing, agent: agent, role: "listing_agent")
        patch listing_listing_agent_path(listing, la), params: { listing_agent: { role: "selling_agent" } }
        expect(la.reload.role).to eq("selling_agent")
      end
    end

    describe "DELETE /listings/:id/listing_agents/:id" do
      it "destroys the listing agent" do
        la = create(:listing_agent, listing: listing, agent: agent)
        expect {
          delete listing_listing_agent_path(listing, la)
        }.to change(ListingAgent, :count).by(-1)
      end

      it "redirects to the listing" do
        la = create(:listing_agent, listing: listing, agent: agent)
        delete listing_listing_agent_path(listing, la)
        expect(response).to redirect_to(listing_path(listing))
      end
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's listing" do
      other_listing = create(:listing)
      get listing_listing_agents_path(other_listing)
      expect(response).to have_http_status(:not_found)
    end
  end
end
