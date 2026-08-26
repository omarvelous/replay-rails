require "rails_helper"

RSpec.describe "Admin::Dashboard" do
  before { host! "admin.replay.localhost" }

  describe "GET / (admin root)" do
    it "redirects non-admin users to the app" do
      sign_in(create(:user, admin: false))
      get "/"
      expect(response).to redirect_to(app_root_url(subdomain: "app"))
    end

    it "redirects unauthenticated users" do
      get "/"
      expect(response).to redirect_to(new_session_path)
    end

    it "returns a successful response for admin users" do
      sign_in(create(:user, admin: true))
      get "/"
      expect(response).to be_successful
    end

    it "displays platform stats" do
      sign_in(create(:user, admin: true))
      get "/"
      expect(response.body).to include("Accounts")
      expect(response.body).to include("Players")
    end
  end
end
