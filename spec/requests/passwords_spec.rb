require "rails_helper"

RSpec.describe "Passwords" do
  describe "GET /passwords/new" do
    it "returns a successful response" do
      get new_password_path
      expect(response).to be_successful
    end
  end

  describe "POST /passwords" do
    it "redirects with notice regardless of email existence" do
      post passwords_path, params: { email_address: "unknown@example.com" }
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects with notice for a valid email" do
      create(:user, email_address: "test@example.com")
      post passwords_path, params: { email_address: "test@example.com" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "GET /passwords/:token/edit" do
    it "redirects with alert for an invalid token" do
      get edit_password_path("bad-token")
      expect(response).to redirect_to(new_password_path)
    end
  end

  describe "PATCH /passwords/:token" do
    it "redirects with alert for an invalid token" do
      patch password_path("bad-token"), params: { password: "newpassword", password_confirmation: "newpassword" }
      expect(response).to redirect_to(new_password_path)
    end
  end
end
