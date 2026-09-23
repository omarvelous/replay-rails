require "rails_helper"

RSpec.describe Authorizable do
  let(:account) { create(:account) }
  let(:user) { create(:user) }

  describe "#membership_on" do
    it "returns the account_user for the given account" do
      account_user = create(:account_user, user: user, account: account, role: "agent")
      expect(user.membership_on(account)).to eq(account_user)
    end

    it "returns nil when not a member" do
      expect(user.membership_on(account)).to be_nil
    end
  end

  describe "#member_of?" do
    it "returns true when the user belongs to the account" do
      create(:account_user, user: user, account: account)
      expect(user.member_of?(account)).to be true
    end

    it "returns false when the user does not belong" do
      expect(user.member_of?(account)).to be false
    end
  end

  describe "#owner_of?" do
    it "returns true when the user is an owner" do
      create(:account_user, user: user, account: account, role: "owner")
      expect(user.owner_of?(account)).to be true
    end

    it "returns false when the user is not an owner" do
      create(:account_user, user: user, account: account, role: "agent")
      expect(user.owner_of?(account)).to be false
    end

    it "returns false when not a member" do
      expect(user.owner_of?(account)).to be false
    end
  end

  describe "#can_manage?" do
    it "returns true for owners" do
      create(:account_user, user: user, account: account, role: "owner")
      expect(user.can_manage?(account)).to be true
    end

    it "returns true for managers" do
      create(:account_user, user: user, account: account, role: "manager")
      expect(user.can_manage?(account)).to be true
    end

    it "returns false for agents" do
      create(:account_user, user: user, account: account, role: "agent")
      expect(user.can_manage?(account)).to be false
    end

    it "returns false when not a member" do
      expect(user.can_manage?(account)).to be false
    end
  end
end
