require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:account) { create(:account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(nil, user: user, account: account, account_user: account_user) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(nil, user: user, account: account, account_user: account_user) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(nil, user: user, account: account, account_user: account_user) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end

  context "when user is nil" do
    let(:policy) { described_class.new(nil, user: nil, account: account, account_user: nil) }

    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end
end
