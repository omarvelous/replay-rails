require "rails_helper"

RSpec.describe AccountUser do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user) }
  end

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:role).in_array(AccountUser::ROLES) }

    it "enforces uniqueness of user per account" do
      account = create(:account)
      user = create(:user)
      create(:account_user, account: account, user: user)

      duplicate = build(:account_user, account: account, user: user)
      expect(duplicate).not_to be_valid
    end
  end

  describe "role predicates" do
    it { expect(build(:account_user, role: "owner")).to be_owner }
    it { expect(build(:account_user, role: "manager")).to be_manager }
    it { expect(build(:account_user, role: "agent")).to be_agent_role }
  end

  describe "#can_manage?" do
    it "returns true for owners" do
      expect(build(:account_user, role: "owner").can_manage?).to be true
    end

    it "returns true for managers" do
      expect(build(:account_user, role: "manager").can_manage?).to be true
    end

    it "returns false for agents" do
      expect(build(:account_user, role: "agent").can_manage?).to be false
    end
  end

  describe "constants" do
    it "defines ROLES" do
      expect(AccountUser::ROLES).to eq(%w[owner manager agent])
    end
  end
end
