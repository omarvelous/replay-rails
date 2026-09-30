require "rails_helper"

RSpec.describe AccountPolicy do
  let(:account) { create(:account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(account, user: user, account: account, account_user: account_user) }

    it { expect(policy).to permit(:edit?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
    it { expect(policy).to permit(:switch?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(account, user: user, account: account, account_user: account_user) }

    it { expect(policy).not_to permit(:edit?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
    it { expect(policy).to permit(:switch?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(account, user: user, account: account, account_user: account_user) }

    it { expect(policy).not_to permit(:edit?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
    it { expect(policy).to permit(:switch?) }
  end

  describe "scope" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:account_user) { user.membership_on(account) }
    let(:other_account) { create(:account) }

    it "returns only accounts the user belongs to" do
      other_account # create it
      policy = described_class.new(account, user: user, account: account, account_user: account_user)
      scope = policy.apply_scope(Account.all, type: :active_record_relation)
      expect(scope).to include(account)
      expect(scope).not_to include(other_account)
    end

    it "includes all accounts the user is a member of" do
      create(:account_user, user: user, account: other_account, role: "agent")
      policy = described_class.new(account, user: user, account: account, account_user: account_user)
      scope = policy.apply_scope(Account.all, type: :active_record_relation)
      expect(scope).to include(account, other_account)
    end
  end
end
