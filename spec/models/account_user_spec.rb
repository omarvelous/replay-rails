require "rails_helper"

RSpec.describe AccountUser do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:role).in_array(AccountUser::ROLES) }

    it "enforces one membership per user per account" do
      account = create(:account)
      user = create(:user)
      create(:account_user, account: account, user: user, role: "manager")

      duplicate = build(:account_user, account: account, user: user, role: "agent")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows the same user on different accounts" do
      user = create(:user)
      create(:account_user, user: user, role: "manager")

      other_account = build(:account_user, user: user, role: "agent")
      expect(other_account).to be_valid
    end
  end

  describe "#at_least?" do
    let(:account) { create(:account) }

    it "owner is at least owner" do
      au = build(:account_user, account: account, role: "owner")
      expect(au.at_least?("owner")).to be true
    end

    it "owner is at least manager" do
      au = build(:account_user, account: account, role: "owner")
      expect(au.at_least?("manager")).to be true
    end

    it "owner is at least agent" do
      au = build(:account_user, account: account, role: "owner")
      expect(au.at_least?("agent")).to be true
    end

    it "manager is at least manager" do
      au = build(:account_user, account: account, role: "manager")
      expect(au.at_least?("manager")).to be true
    end

    it "manager is at least agent" do
      au = build(:account_user, account: account, role: "manager")
      expect(au.at_least?("agent")).to be true
    end

    it "manager is NOT at least owner" do
      au = build(:account_user, account: account, role: "manager")
      expect(au.at_least?("owner")).to be false
    end

    it "agent is at least agent" do
      au = build(:account_user, account: account, role: "agent")
      expect(au.at_least?("agent")).to be true
    end

    it "agent is NOT at least manager" do
      au = build(:account_user, account: account, role: "agent")
      expect(au.at_least?("manager")).to be false
    end
  end

  describe "constants" do
    it "defines ROLES" do
      expect(AccountUser::ROLES).to eq(%w[owner manager agent])
    end
  end

  describe "#destroy" do
    it "prevents destroying the last owner of an account" do
      account = create(:account)
      owner = create(:account_user, account: account, role: "owner")

      expect(owner.destroy).to be_falsey
      expect(owner.errors[:base]).to include("Cannot remove the last owner")
      expect(described_class.exists?(owner.id)).to be true
    end

    it "allows destroying an owner when another owner exists" do
      account = create(:account)
      owner1 = create(:account_user, account: account, role: "owner")
      create(:account_user, account: account, role: "owner", user: create(:user))

      expect(owner1.destroy).to be_truthy
      expect(described_class.exists?(owner1.id)).to be false
    end

    it "allows destroying a non-owner role freely" do
      account = create(:account)
      create(:account_user, account: account, role: "owner")
      manager = create(:account_user, :manager, account: account, user: create(:user))

      expect(manager.destroy).to be_truthy
      expect(described_class.exists?(manager.id)).to be false
    end
  end
end
