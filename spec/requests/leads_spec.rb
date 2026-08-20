require "rails_helper"

RSpec.describe "Leads" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /leads" do
    it "returns a successful response" do
      get leads_path
      expect(response).to be_successful
    end

    it "lists leads for the current account" do
      lead = create(:lead, account: account, name: "Jane Doe")
      create(:lead, name: "Other Account Lead")

      get leads_path
      expect(response.body).to include("Jane Doe")
      expect(response.body).not_to include("Other Account Lead")
    end

    it "filters by status" do
      create(:lead, account: account, name: "New Lead", status: "new")
      create(:lead, account: account, name: "Closed Lead", status: "closed")

      get leads_path, params: { status: "new" }
      expect(response.body).to include("New Lead")
      expect(response.body).not_to include("Closed Lead")
    end
  end

  describe "GET /leads/:id" do
    it "returns a successful response" do
      lead = create(:lead, account: account)
      get lead_path(lead)
      expect(response).to be_successful
    end

    it "returns 404 for another account's lead" do
      other_lead = create(:lead)
      get lead_path(other_lead)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /leads/:id" do
    it "updates the lead status" do
      lead = create(:lead, account: account, status: "new")
      patch lead_path(lead), params: { lead: { status: "contacted" } }
      expect(lead.reload.status).to eq("contacted")
      expect(response).to redirect_to(lead_path(lead))
    end

    it "reassigns the lead to a new agent" do
      lead = create(:lead, account: account)
      agent = create(:agent, account: account)

      patch lead_path(lead), params: { lead: { agent_id: agent.id } }
      expect(lead.current_agent).to eq(agent)
    end
  end

end
