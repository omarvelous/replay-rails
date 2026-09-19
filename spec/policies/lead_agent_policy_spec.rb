require "rails_helper"

RSpec.describe LeadAgentPolicy do
  let(:account) { create(:account) }
  let(:lead_agent) { create(:lead_agent) }

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(lead_agent, user: user, account: account, account_user: account_user) }

    it { expect(policy).to permit(:new?) }
    it { expect(policy).to permit(:create?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(lead_agent, user: user, account: account, account_user: account_user) }

    it { expect(policy).not_to permit(:new?) }
    it { expect(policy).not_to permit(:create?) }
  end
end
