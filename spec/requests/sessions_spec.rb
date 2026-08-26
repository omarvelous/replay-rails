require "rails_helper"

RSpec.describe "Sessions" do
  let(:user) { create(:user) }

  describe "POST /session (login)" do
    context "with valid credentials" do
      it "creates a Session record" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "password123" }
        }.to change(Session, :count).by(1)
      end

      it "redirects after login" do
        post session_path, params: { email_address: user.email_address, password: "password123" }
        expect(response).to be_redirect
      end
    end

    context "with invalid credentials" do
      it "does not create a Session record" do
        expect {
          post session_path, params: { email_address: user.email_address, password: "wrong" }
        }.not_to change(Session, :count)
      end

      it "redirects back to login" do
        post session_path, params: { email_address: user.email_address, password: "wrong" }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "DELETE /session (logout)" do
    context "when unauthenticated" do
      it "redirects to login" do
        delete session_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when authenticated" do
      before do
        post session_path, params: { email_address: user.email_address, password: "password123" }
      end

      it "destroys the Session record" do
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
end
