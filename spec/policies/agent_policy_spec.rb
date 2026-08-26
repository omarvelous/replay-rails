require "rails_helper"

RSpec.describe AgentPolicy do
  let(:account) { create(:account) }
  let(:agent) { create(:agent, account: account) }

  context "as a manager" do
    let(:account_user) { create(:account_user, :manager, account: account) }
    subject { described_class.new(account_user, agent) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as an agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.account_users.first }
    subject { described_class.new(account_user, agent) }

    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create destroy]) }

    context "on their own profile" do
      let(:agent) { create(:agent, account: account, user: user) }

      it { is_expected.to permit_actions(%i[update edit]) }
    end

    context "on another agent's profile" do
      it { is_expected.to forbid_actions(%i[update edit]) }
    end
  end
end
