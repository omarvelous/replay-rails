require "rails_helper"

RSpec.describe Invite do
  subject(:invite) { build(:invite) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:invited_by).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_inclusion_of(:role).in_array(Invite::ROLES) }

    it "prevents inviting a user who already has this role" do
      account = create(:account)
      user = create(:user, account: account, role: "agent")

      invite = build(:invite, account: account, email: user.email_address, role: "agent")
      expect(invite).not_to be_valid
      expect(invite.errors[:email]).to include("already has the agent role on this account")
    end

    it "allows inviting an existing member with a different role" do
      account = create(:account)
      user = create(:user, account: account, role: "agent")

      invite = build(:invite, account: account, email: user.email_address, role: "manager")
      expect(invite).to be_valid
    end
  end

  describe "token generation" do
    it "generates a token before create" do
      invite = create(:invite)
      expect(invite.token).to be_present
      expect(invite.token.length).to be >= 20
    end
  end

  describe "email normalization" do
    it "normalizes email to lowercase" do
      invite = create(:invite, email: "  TEST@EXAMPLE.COM  ")
      expect(invite.email).to eq("test@example.com")
    end
  end

  describe "scopes" do
    it ".pending returns unexpired, unaccepted invites" do
      pending_invite = create(:invite)
      create(:invite, accepted_at: Time.current)
      create(:invite, created_at: 8.days.ago)

      expect(described_class.pending).to eq([ pending_invite ])
    end

    it ".expired returns unaccepted invites older than 7 days" do
      create(:invite)
      expired = create(:invite, created_at: 8.days.ago)

      expect(described_class.expired).to eq([ expired ])
    end
  end

  describe "#pending?" do
    it "returns true for a fresh unaccepted invite" do
      expect(create(:invite)).to be_pending
    end

    it "returns false when accepted" do
      expect(create(:invite, accepted_at: Time.current)).not_to be_pending
    end

    it "returns false when expired" do
      expect(create(:invite, created_at: 8.days.ago)).not_to be_pending
    end
  end

  describe "#expired?" do
    it "returns true when older than 7 days and unaccepted" do
      expect(create(:invite, created_at: 8.days.ago)).to be_expired
    end

    it "returns false when fresh" do
      expect(create(:invite)).not_to be_expired
    end
  end

  describe "#accepted?" do
    it "returns true when accepted_at is set" do
      expect(create(:invite, accepted_at: Time.current)).to be_accepted
    end

    it "returns false when not accepted" do
      expect(create(:invite)).not_to be_accepted
    end
  end

end
