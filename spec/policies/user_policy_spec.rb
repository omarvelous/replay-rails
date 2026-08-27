require "rails_helper"

RSpec.describe UserPolicy do
  let(:account) { create(:account) }
  let(:member) { create(:user, account: account, role: "agent") }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { described_class.new(member, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(member, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:policy) { described_class.new(member, user: user, account: account) }

    it { expect(policy).not_to permit(:index?) }
    it { expect(policy).not_to permit(:show?) }
  end

  describe "scope" do
    let!(:account_member) { create(:user, account: account, role: "agent") }
    let!(:other_account_user) { create(:user) }
    let(:user) { create(:user, account: account, role: "owner") }

    it "returns only users who are members of the account" do
      scope = described_class.new(account_member, user: user, account: account)
                             .apply_scope(User.all, type: :active_record_relation)
      expect(scope).to include(account_member)
      expect(scope).to include(user)
      expect(scope).not_to include(other_account_user)
    end
  end
end
