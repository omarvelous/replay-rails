require "rails_helper"

RSpec.describe "Settings" do
  let(:account) { create(:account, name: "Original Name") }

  describe "GET /settings" do
    it "returns a successful response for any member" do
      user = create(:user, account: account)
      sign_in(user)
      get settings_path
      expect(response).to be_successful
      expect(response.body).to include("Original Name")
    end
  end

  describe "PATCH /settings" do
    context "as owner" do
      let(:owner) { create(:user, account: account, role: "owner") }

      before { sign_in(owner) }

      it "updates the account name" do
        patch settings_path, params: { account: { name: "New Name" } }
        expect(account.reload.name).to eq("New Name")
      end

      it "redirects with a notice" do
        patch settings_path, params: { account: { name: "New Name" } }
        expect(response).to redirect_to(settings_path)
      end

      it "returns 422 with blank name" do
        patch settings_path, params: { account: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as agent" do
      let(:agent) { create(:user, account: account, role: "agent") }

      before { sign_in(agent) }

      it "redirects with unauthorized message" do
        patch settings_path, params: { account: { name: "Hacked" } }
        expect(response).to redirect_to(app_root_path)
        expect(account.reload.name).to eq("Original Name")
      end
    end
  end
end
