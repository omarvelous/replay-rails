require "rails_helper"

RSpec.describe "Users (Team)" do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: "owner") }

  before { sign_in(owner) }

  describe "GET /users" do
    it "returns a successful response" do
      get users_path
      expect(response).to be_successful
    end


    it "lists members of the current account" do
      agent = create(:user, account: account, role: "agent", first_name: "Jane")
      get users_path
      expect(response.body).to include("Jane")
      expect(response.body).to include(owner.first_name)
    end

    it "does not list users from other accounts" do
      other_user = create(:user, first_name: "Outsider")
      get users_path
      expect(response.body).not_to include("Outsider")
    end

    it "shows roles for each member" do
      get users_path
      expect(response.body).to include("Owner")
    end
  end

  describe "GET /users/:id" do
    it "returns a successful response" do
      get user_path(owner)
      expect(response).to be_successful
    end

    it "shows the member's details" do
      get user_path(owner)
      expect(response.body).to include(owner.first_name)
      expect(response.body).to include(owner.email_address)
    end

    it "shows the member's roles" do
      get user_path(owner)
      expect(response.body).to include("Owner")
    end

    it "returns 404 for a user not on this account" do
      other_user = create(:user)
      get user_path(other_user)
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when user is agent" do
    let(:agent) { create(:user, account: account, role: "agent") }

    before { sign_in(agent) }

    it "denies access to index" do
      get users_path
      expect(response).to redirect_to(app_root_path)
    end

    it "denies access to show" do
      get user_path(owner)
      expect(response).to redirect_to(app_root_path)
    end
  end
end
