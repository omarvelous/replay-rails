require "rails_helper"

RSpec.describe "Accounts" do
  describe "GET /accounts/new (signup form)" do
    it "returns a successful response" do
      get new_account_path
      expect(response).to be_successful
    end
  end

  describe "POST /accounts (signup)" do
    let(:valid_params) do
      {
        account: {},
        user: {
          first_name: "Jane",
          last_name: "Smith",
          email_address: "jane@example.com",
          phone: "+12125551234",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    context "with valid params" do
      it "creates an Account" do
        expect {
          post accounts_path, params: valid_params
        }.to change(Account, :count).by(1)
      end

      it "creates a User associated with the Account" do
        expect {
          post accounts_path, params: valid_params
        }.to change(User, :count).by(1)
        expect(User.last.accounts.first).to be_a(Account)
      end

      it "redirects after signup" do
        post accounts_path, params: valid_params
        expect(response).to be_redirect
      end
    end

    context "with missing first_name" do
      it "does not create an Account or User" do
        params = valid_params.deep_merge(user: { first_name: "" })
        expect {
          post accounts_path, params: params
        }.not_to change(Account, :count)
        expect(User.count).to eq(0)
      end

      it "returns 422" do
        params = valid_params.deep_merge(user: { first_name: "" })
        post accounts_path, params: params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with duplicate email_address" do
      before { create(:user, email_address: "jane@example.com") }

      it "does not create a new Account or User" do
        expect {
          post accounts_path, params: valid_params
        }.not_to change(Account, :count)
      end

      it "returns 422" do
        post accounts_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
