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

    context "when account is not set but user has accounts" do
      it "falls back to the user's first account" do
        user = create(:user)
        session = user.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")
        described_class.session = session

        expect(described_class.account).to eq(user.accounts.first)
      end
    end

    context "when no session exists" do
      it "returns nil" do
        expect(described_class.account).to be_nil
      end
    end
  end
end
