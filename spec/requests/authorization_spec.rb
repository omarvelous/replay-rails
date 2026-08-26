require "rails_helper"

RSpec.describe "Authorization" do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }

  describe "as an agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:agent) { create(:agent, account: account, user: user) }

    before do
      create(:listing_agent, listing: listing, agent: agent)
      sign_in(user)
    end

    it "can view listings index" do
      get listings_path
      expect(response).to be_successful
    end

    it "can view their own listing" do
      get listing_path(listing)
      expect(response).to be_successful
    end

    it "cannot create a listing" do
      post listings_path, params: { listing: { address: "123 Main St", price: 500_000, status: "active" } }
      expect(response).to redirect_to(app_root_path)
      expect(flash[:alert]).to be_present
    end

    it "cannot delete a listing" do
      delete listing_path(listing)
      expect(response).to redirect_to(app_root_path)
    end

    it "can view their own leads" do
      lead = create(:lead, account: account)
      lead.lead_agents.create!(agent: agent)

      get leads_path
      expect(response).to be_successful
      expect(response.body).to include(lead.name)
    end

    it "cannot see another agent's leads" do
      other_lead = create(:lead, account: account, name: "Other Agent Lead")
      get leads_path
      expect(response.body).not_to include("Other Agent Lead")
    end

    it "cannot assign agents to leads" do
      lead = create(:lead, account: account)
      lead.lead_agents.create!(agent: agent)

      get new_lead_lead_agent_path(lead)
      expect(response).to redirect_to(app_root_path)
    end

    it "can view sites (read-only)" do
      create(:site, account: account, name: "Main Office")
      get sites_path
      expect(response).to be_successful
    end

    it "cannot create a site" do
      post sites_path, params: { site: { name: "New Office", address: "456 Elm St" } }
      expect(response).to redirect_to(app_root_path)
    end
  end

  describe "as a manager" do
    let(:user) { create(:user, account: account, role: "manager") }

    before { sign_in(user) }

    it "can create a listing" do
      post listings_path, params: { listing: { address: "123 Main St", price: 500_000, status: "active" } }
      expect(response).to be_redirect
      expect(Listing.last.address).to eq("123 Main St")
    end

    it "can delete a listing" do
      delete listing_path(listing)
      expect(response).to redirect_to(listings_path)
    end

    it "can view all leads" do
      create(:lead, account: account, name: "Any Lead")
      get leads_path
      expect(response.body).to include("Any Lead")
    end

    it "can assign agents to leads" do
      lead = create(:lead, account: account)
      get new_lead_lead_agent_path(lead)
      expect(response).to be_successful
    end
  end

  describe "as an owner" do
    let(:user) { create(:user, account: account, role: "owner") }

    before { sign_in(user) }

    it "can do everything a manager can" do
      post listings_path, params: { listing: { address: "789 Oak Ave", price: 750_000, status: "active" } }
      expect(response).to be_redirect
    end
  end
end
