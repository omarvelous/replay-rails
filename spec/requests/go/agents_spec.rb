require "rails_helper"

RSpec.describe "Go::Agents" do
  let(:account) { create(:account) }
  let(:agent) { create(:agent, account: account) }

  before { host! "replay.localhost" }

  describe "GET /go/agents/:id" do
    it "returns a successful response without authentication" do
      get go_agent_path(agent)
      expect(response).to be_successful
    end

    it "displays agent details" do
      get go_agent_path(agent)
      expect(response.body).to include(agent.name)
      expect(response.body).to include(agent.email)
    end

    it "displays the agent's active listings" do
      active = create(:listing, account: account, status: "active")
      sold = create(:listing, account: account, status: "sold")
      create(:listing_agent, listing: active, agent: agent)
      create(:listing_agent, listing: sold, agent: agent)

      get go_agent_path(agent)
      expect(response.body).to include(active.address)
      expect(response.body).not_to include(sold.address)
    end

    it "renders the lead form" do
      get go_agent_path(agent)
      expect(response.body).to include("Send inquiry")
    end
  end
end
