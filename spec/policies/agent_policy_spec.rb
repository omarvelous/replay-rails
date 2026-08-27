require "rails_helper"

RSpec.describe AgentPolicy do
  let(:account) { create(:account) }
  let(:agent) { create(:agent, account: account) }

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(agent, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:policy) { described_class.new(agent, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:destroy?) }

    context "when viewing their own profile" do
      let(:agent) { create(:agent, account: account, user: user) }

      it { expect(policy).to permit(:update?) }
      it { expect(policy).to permit(:edit?) }
    end

    context "when viewing another agent's profile" do
      it { expect(policy).not_to permit(:update?) }
      it { expect(policy).not_to permit(:edit?) }
    end
  end
end
