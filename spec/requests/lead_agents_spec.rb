require "rails_helper"

RSpec.describe "LeadAgents" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:lead) { create(:lead, account: account) }
  let(:agent) { create(:agent, account: account) }

  before { sign_in(user) }

  describe "POST /leads/:lead_id/lead_agents" do
    it "assigns an agent to the lead" do
      expect {
        post lead_lead_agents_path(lead), params: { lead_agent: { agent_id: agent.id } }
      }.to change(LeadAgent, :count).by(1)

      expect(lead.current_agent).to eq(agent)
    end

    it "redirects to the lead" do
      post lead_lead_agents_path(lead), params: { lead_agent: { agent_id: agent.id } }
      expect(response).to redirect_to(lead_path(lead))
    end

    it "allows reassignment by creating a new record" do
      other_agent = create(:agent, account: account)
      lead.lead_agents.create!(agent: agent)

      post lead_lead_agents_path(lead), params: { lead_agent: { agent_id: other_agent.id } }

      expect(lead.current_agent).to eq(other_agent)
      expect(lead.lead_agents.count).to eq(2)
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's lead" do
      other_lead = create(:lead)
      post lead_lead_agents_path(other_lead), params: { lead_agent: { agent_id: agent.id } }
      expect(response).to have_http_status(:not_found)
    end
  end
end
