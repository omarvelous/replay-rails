require "rails_helper"

RSpec.describe "Account switching", type: :request do
  let(:account_a) { create(:account, name: "Brokerage Alpha") }
  let(:account_b) { create(:account, name: "Brokerage Beta") }
  let(:user) { create(:user, account: account_a) }

  before do
    create(:account_user, user: user, account: account_b, role: "owner")
    sign_in(user)
  end

  describe "session-based account resolution" do
    it "defaults to the user's first account when no account_id in session" do
      listing_a = ActsAsTenant.with_tenant(account_a) { create(:listing, account: account_a) }

      get listings_path
      expect(response).to be_successful
      expect(response.body).to include(listing_a.address)
    end

    it "resolves current account from session[:account_id]" do
      listing_b = ActsAsTenant.with_tenant(account_b) { create(:listing, account: account_b) }
      listing_a = ActsAsTenant.with_tenant(account_a) { create(:listing, account: account_a) }

      # Default: should see account_a's listing
      get listings_path
      expect(response.body).to include(listing_a.address)
      expect(response.body).not_to include(listing_b.address)

      # Switch to account_b
      post account_switch_path, params: { account_id: account_b.public_id }

      # Now should see account_b's listing
      get listings_path
      expect(response.body).to include(listing_b.address)
      expect(response.body).not_to include(listing_a.address)
    end
  end

  describe "POST /account/switch" do
    it "sets session[:account_id] and redirects with notice" do
      post account_switch_path, params: { account_id: account_b.public_id }
      expect(response).to redirect_to(app_root_path)
      expect(flash[:notice]).to eq("Switched to Brokerage Beta")
    end

    it "returns 404 for an account the user does not belong to" do
      other_account = create(:account, name: "Forbidden")

      post account_switch_path, params: { account_id: other_account.public_id }
      expect(response).to have_http_status(:not_found)
    end
  end
end
