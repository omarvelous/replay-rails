require "rails_helper"

RSpec.describe "AccountUsers (Roles)" do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: "owner") }

  before { sign_in(owner) }

  describe "GET /users/:user_id/account_users" do
    it "returns a successful response" do
      get user_account_users_path(owner)
      expect(response).to be_successful
    end

    it "shows the user's roles for this account" do
      get user_account_users_path(owner)
      expect(response.body).to include("Owner")
    end
  end

  describe "POST /users/:user_id/account_users" do
    let(:member) { create(:user, account: account, role: "agent") }

    it "adds a role to the user" do
      expect {
        post user_account_users_path(member), params: { account_user: { role: "manager" } }
      }.to change { member.account_users.where(account: account).count }.by(1)
    end

    it "redirects with notice on success" do
      post user_account_users_path(member), params: { account_user: { role: "manager" } }
      expect(response).to redirect_to(user_account_users_path(member))
      expect(flash[:notice]).to eq("Role added.")
    end

    it "rejects duplicate roles" do
      post user_account_users_path(member), params: { account_user: { role: "agent" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects invalid roles" do
      post user_account_users_path(member), params: { account_user: { role: "superadmin" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /users/:user_id/account_users/:id" do
    it "removes a role from the user" do
      member = create(:user, account: account, role: "agent")
      au = member.account_users.find_by(account: account, role: "agent")

      expect {
        delete user_account_user_path(member, au)
      }.to change { member.account_users.where(account: account).count }.by(-1)
    end

    it "redirects with notice on success" do
      member = create(:user, account: account, role: "agent")
      au = member.account_users.find_by(account: account, role: "agent")

      delete user_account_user_path(member, au)
      expect(response).to redirect_to(user_account_users_path(member))
      expect(flash[:notice]).to eq("Role removed.")
    end

    it "prevents removing the last owner" do
      au = owner.account_users.find_by(account: account, role: "owner")

      expect {
        delete user_account_user_path(owner, au)
      }.not_to change { AccountUser.count }

      expect(response).to redirect_to(user_account_users_path(owner))
      expect(flash[:alert]).to include("Cannot remove the last owner")
    end

    it "allows removing an owner when another owner exists" do
      other_owner = create(:user, account: account, role: "owner")
      au = owner.account_users.find_by(account: account, role: "owner")

      expect {
        delete user_account_user_path(owner, au)
      }.to change { AccountUser.where(role: "owner", account: account).count }.by(-1)
    end
  end

  context "when user is agent" do
    let(:agent) { create(:user, account: account, role: "agent") }

    before { sign_in(agent) }

    it "denies access to index" do
      get user_account_users_path(agent)
      expect(response).to redirect_to(app_root_path)
    end

    it "denies creating a role" do
      post user_account_users_path(agent), params: { account_user: { role: "manager" } }
      expect(response).to redirect_to(app_root_path)
    end

    it "denies destroying a role" do
      au = agent.account_users.find_by(account: account)
      delete user_account_user_path(agent, au)
      expect(response).to redirect_to(app_root_path)
    end
  end

  describe "tenant isolation" do
    it "returns 404 for a user not on this account" do
      other_user = create(:user)
      get user_account_users_path(other_user)
      expect(response).to have_http_status(:not_found)
    end
  end
end
