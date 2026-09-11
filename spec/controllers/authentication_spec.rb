require "rails_helper"

RSpec.describe "Authentication", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  describe "current_user and current_account" do
    before { sign_in(user) }

    it "exposes current_user to the view" do
      get app_root_path
      expect(response.body).to include(user.first_name)
    end

    it "returns successful response for authenticated user" do
      get app_root_path
      expect(response).to be_successful
    end

    it "defines current_user as a public method" do
      expect(ApplicationController.public_method_defined?(:current_user)).to be true
    end

    it "defines current_account as a public method" do
      expect(ApplicationController.public_method_defined?(:current_account)).to be true
    end
  end

  describe "unauthenticated access" do
    it "redirects to login when not signed in" do
      get listings_path
      expect(response).to redirect_to(new_session_path)
    end

    it "allows access to public pages" do
      host! "replay.localhost"
      get "/"
      expect(response).to be_successful
    end
  end

  describe "sign in" do
    it "creates a session on valid credentials" do
      expect {
        post session_path, params: { email_address: user.email_address, password: "password123" }
      }.to change(Session, :count).by(1)
    end

    it "rejects invalid credentials" do
      post session_path, params: { email_address: user.email_address, password: "wrong" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "sign out" do
    before { sign_in(user) }

    it "destroys the session" do
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end

    it "redirects to login" do
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
