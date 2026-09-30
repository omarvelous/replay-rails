require "rails_helper"

RSpec.describe Current do
  after { described_class.reset }

  describe "#account" do
    context "when account is explicitly set" do
      it "returns the explicitly set account" do
        account = create(:account)
        described_class.account = account
        expect(described_class.account).to eq(account)
      end
    end

    context "when account is not set" do
      it "returns nil (controller resolves account from session)" do
        user = create(:user)
        session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
        described_class.session = session

        expect(described_class.account).to be_nil
      end
    end

    context "when no session exists" do
      it "returns nil" do
        expect(described_class.account).to be_nil
      end
    end
  end

  describe "#account_user" do
    it "returns the real membership when one exists" do
      user = create(:user)
      account = user.accounts.first
      session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
      described_class.session = session
      described_class.account = account

      expect(described_class.account_user).to be_a(AccountUser)
      expect(described_class.account_user.account).to eq(account)
    end

    it "returns AdminAccountUser for admin without membership" do
      admin = create(:user, admin: true)
      other_account = create(:account, name: "Other Brokerage")
      session = admin.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
      described_class.session = session
      described_class.account = other_account

      expect(described_class.account_user).to be_a(AdminAccountUser)
      expect(described_class.account_user.role).to eq("owner")
    end

    it "returns nil for non-admin without membership" do
      user = create(:user)
      other_account = create(:account, name: "Other Brokerage")
      session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
      described_class.session = session
      described_class.account = other_account

      expect(described_class.account_user).to be_nil
    end
  end
end
