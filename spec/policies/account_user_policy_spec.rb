require "rails_helper"

RSpec.describe AccountUserPolicy do
  let(:account) { create(:account) }
  let(:record) { create(:account_user, account: account, role: "agent") }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { described_class.new(record, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(record, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:policy) { described_class.new(record, user: user, account: account) }

    it { expect(policy).not_to permit(:index?) }
    it { expect(policy).not_to permit(:show?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:destroy?) }
  end

  describe "scope" do
    let(:user) { create(:user, account: account, role: "owner") }
    let!(:account_au) { create(:account_user, account: account, role: "agent") }
    let!(:other_au) { create(:account_user, role: "agent") }

    it "returns only account_users for the current account" do
      scope = described_class.new(account_au, user: user, account: account)
                             .apply_scope(AccountUser.all, type: :active_record_relation)
      expect(scope).to include(account_au)
      expect(scope).not_to include(other_au)
    end
  end
end
