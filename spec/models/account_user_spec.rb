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
end
