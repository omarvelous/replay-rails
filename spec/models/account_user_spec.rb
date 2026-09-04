require "rails_helper"

RSpec.describe AccountUser do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:role).in_array(AccountUser::ROLES) }

    it "allows multiple roles for the same user on the same account" do
      account = create(:account)
      user = create(:user)
      create(:account_user, account: account, user: user, role: "manager")

      agent_role = build(:account_user, account: account, user: user, role: "agent")
      expect(agent_role).to be_valid
    end

    it "prevents duplicate roles for the same user on the same account" do
      account = create(:account)
      user = create(:user)
      create(:account_user, account: account, user: user, role: "manager")

      duplicate = build(:account_user, account: account, user: user, role: "manager")
      expect(duplicate).not_to be_valid
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
