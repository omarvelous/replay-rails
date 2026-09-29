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

  describe "GET /users/:id/edit (profile)" do
    it "allows a user to edit their own profile" do
      get edit_user_path(owner)
      expect(response).to be_successful
      expect(response.body).to include(owner.first_name)
    end

    it "denies editing another user's profile" do
      other = create(:user, account: account, role: "agent")
      get edit_user_path(other)
      expect(response).to redirect_to(app_root_path)
    end
  end

  describe "PATCH /users/:id (profile update)" do
    it "updates the user's own name" do
      patch user_path(owner), params: { user: { first_name: "Updated" } }
      expect(owner.reload.first_name).to eq("Updated")
      expect(response).to redirect_to(user_path(owner))
    end

    it "updates email address" do
      patch user_path(owner), params: { user: { email_address: "new@example.com" } }
      expect(owner.reload.email_address).to eq("new@example.com")
    end

    it "returns 422 with invalid params" do
      patch user_path(owner), params: { user: { first_name: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "denies updating another user" do
      other = create(:user, account: account, role: "agent")
      patch user_path(other), params: { user: { first_name: "Hacked" } }
      expect(response).to redirect_to(app_root_path)
      expect(other.reload.first_name).not_to eq("Hacked")
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
