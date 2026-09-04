require "rails_helper"

RSpec.describe "Invites" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: "owner") }

  before { sign_in(user) }

  describe "GET /invites" do
    it "returns a successful response" do
      get invites_path
      expect(response).to be_successful
    end


    it "shows pending invites" do
      invite = create(:invite, account: account, email: "pending@example.com", invited_by: user)
      get invites_path
      expect(response.body).to include("pending@example.com")
    end
  end

  describe "GET /invites/new" do
    it "returns a successful response" do
      get new_invite_path
      expect(response).to be_successful
    end
  end

  describe "POST /invites" do
    it "creates an invite and enqueues email" do
      expect {
        post invites_path, params: { invite: { email: "newagent@example.com", invited_role: "agent" } }
      }.to change(Invite, :count).by(1)

      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued
      expect(response).to redirect_to(invites_path)
    end

    it "rejects invalid params" do
      post invites_path, params: { invite: { email: "", invited_role: "agent" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    context "when user is manager" do
      let(:user) { create(:user, account: account, role: "manager") }

      it "allows inviting agents" do
        post invites_path, params: { invite: { email: "agent@example.com", invited_role: "agent" } }
        expect(response).to redirect_to(invites_path)
      end

      it "denies inviting managers" do
        post invites_path, params: { invite: { email: "mgr@example.com", invited_role: "manager" } }
        expect(response).to redirect_to(app_root_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is agent" do
      let(:user) { create(:user, account: account, role: "agent") }

      it "denies access" do
        post invites_path, params: { invite: { email: "test@example.com", invited_role: "agent" } }
        expect(response).to redirect_to(app_root_path)
      end
    end
  end

  describe "POST /invites/:token/resend" do
    it "re-sends the invite email and records resent_at" do
      invite = create(:invite, account: account, invited_by: user)
      post resend_invite_path(token: invite.token)
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued
      expect(response).to redirect_to(invites_path)
      expect(flash[:notice]).to eq("Invite resent to #{invite.email}.")
      expect(invite.reload.resent_at).to be_present
    end

    it "does not resend an accepted invite" do
      invite = create(:invite, account: account, invited_by: user, accepted_at: 1.day.ago)
      post resend_invite_path(token: invite.token)
      expect(response).to redirect_to(invites_path)
      expect(flash[:alert]).to be_present
    end

    it "does not resend an expired invite" do
      invite = create(:invite, account: account, invited_by: user, created_at: 8.days.ago)
      post resend_invite_path(token: invite.token)
      expect(response).to redirect_to(invites_path)
      expect(flash[:alert]).to be_present
    end

    context "when user is agent" do
      let(:user) { create(:user, account: account, role: "agent") }

      it "denies access" do
        invite = create(:invite, account: account, invited_by: create(:user, account: account, role: "owner"))
        post resend_invite_path(token: invite.token)
        expect(response).to redirect_to(app_root_path)
      end
    end
  end

  describe "DELETE /invites/:token" do
    it "revokes the invite" do
      invite = create(:invite, account: account, invited_by: user)
      expect {
        delete invite_path(token: invite.token)
      }.to change(Invite, :count).by(-1)
      expect(response).to redirect_to(invites_path)
    end
  end
end
