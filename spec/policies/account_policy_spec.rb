require "rails_helper"

RSpec.describe AccountPolicy do
  let(:account) { create(:account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { described_class.new(account, user: user, account: account) }

    it { expect(policy).to permit(:edit?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(account, user: user, account: account) }

    it { expect(policy).not_to permit(:edit?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:policy) { described_class.new(account, user: user, account: account) }

    it { expect(policy).not_to permit(:edit?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end
end
