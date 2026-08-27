require "rails_helper"

RSpec.describe "Dashboard" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: "owner") }

  before { sign_in(user) }

  describe "GET / (app root)" do
    it "returns a successful response" do
      get app_root_path
      expect(response).to be_successful
    end

    it "shows summary metrics" do
      get app_root_path
      expect(response.body).to include("Screens")
      expect(response.body).to include("Impressions")
      expect(response.body).to include("Scans")
      expect(response.body).to include("Leads")
    end

    it "shows the funnel" do
      get app_root_path
      expect(response.body).to include("Funnel")
    end

    it "shows recent leads" do
      create(:lead, account: account, name: "Jane Doe", status: "new")
      get app_root_path
      expect(response.body).to include("Jane Doe")
    end
  end
end
