require "rails_helper"

RSpec.describe "Invite Accept Flow" do
  let(:account) { create(:account) }
  let(:owner) { create(:user, account: account, role: "owner") }

  describe "GET /invites/:token (show)" do
    context "when logged in with matching email" do
      it "auto-accepts the invite" do
        invite = create(:invite, account: account, email: owner.email_address, role: "manager", invited_by: owner)
        sign_in(owner)

        expect {
          get invite_path(token: invite.token)
        }.to change(AccountUser, :count).by(1)

        expect(invite.reload).to be_accepted
        expect(response).to redirect_to(app_root_path)
      end
    end

    context "when logged in with wrong email" do
      it "denies access" do
        invite = create(:invite, account: account, email: "other@example.com", invited_by: owner)
        sign_in(owner)

        get invite_path(token: invite.token)
        # The owner's email doesn't match "other@example.com"
        # Policy show? returns false → ActionPolicy::Unauthorized → redirect
        expect(response).to redirect_to(app_root_path)
      end
    end

    context "when not logged in and user exists" do
      it "redirects to login" do
        existing_user = create(:user, email_address: "invited@example.com")
        invite = create(:invite, account: account, email: "invited@example.com", invited_by: owner)

        get invite_path(token: invite.token)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when not logged in and user does not exist" do
      it "shows the registration form" do
        invite = create(:invite, account: account, email: "newuser@example.com", invited_by: owner)

        get invite_path(token: invite.token)
        expect(response).to be_successful
        expect(response.body).to include("Join RePlay")
        expect(response.body).to include("newuser@example.com")
      end
    end

    context "when invite is expired" do
      it "shows the expired page" do
        invite = create(:invite, account: account, email: "expired@example.com", invited_by: owner, created_at: 8.days.ago)

        get invite_path(token: invite.token)
        expect(response).to be_successful
        expect(response.body).to include("Invite expired")
      end
    end

    context "when invite is already accepted" do
      it "redirects with notice" do
        invite = create(:invite, account: account, email: "done@example.com", invited_by: owner, accepted_at: 1.day.ago)

        get invite_path(token: invite.token)
        expect(response).to redirect_to(app_root_path)
      end
    end
  end

  describe "PATCH /invites/:token (update — registration)" do
    let(:invite) { create(:invite, account: account, email: "newagent@example.com", invited_by: owner) }

    context "with valid params" do
      it "creates a user, accepts the invite, and starts a session" do
        patch invite_path(token: invite.token), params: {
          user: { first_name: "New", last_name: "Agent", phone: "+12125559999",
                  password: "password123", password_confirmation: "password123" }
        }

        expect(invite.reload).to be_accepted
        new_user = User.find_by(email_address: "newagent@example.com")
        expect(new_user).to be_present
        expect(new_user.first_name).to eq("New")
        expect(AccountUser.exists?(account: account, user: new_user, role: "agent")).to be true
        expect(response).to redirect_to(app_root_path)
      end
    end

    context "with invalid params" do
      it "re-renders the form" do
        patch invite_path(token: invite.token), params: {
          user: { first_name: "", last_name: "", password: "short" }
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when invite is expired" do
      it "redirects with alert" do
        expired_invite = create(:invite, account: account, email: "late@example.com",
                                invited_by: owner, created_at: 8.days.ago)
        patch invite_path(token: expired_invite.token), params: {
          user: { first_name: "Late", last_name: "User", password: "password123",
                  password_confirmation: "password123" }
        }
        expect(response).to redirect_to(app_root_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
