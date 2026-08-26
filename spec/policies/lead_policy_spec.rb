require "rails_helper"

RSpec.describe LeadPolicy do
  let(:account) { create(:account) }
  let(:lead) { create(:lead, account: account) }

  context "as an owner" do
    let(:account_user) { create(:account_user, account: account, role: "owner") }
    subject { described_class.new(account_user, lead) }

    it { is_expected.to permit_actions(%i[index show update destroy]) }
  end

  context "as a manager" do
    let(:account_user) { create(:account_user, :manager, account: account) }
    subject { described_class.new(account_user, lead) }

    it { is_expected.to permit_actions(%i[index show update destroy]) }
  end

  context "as an agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.account_users.first }
    let(:agent) { create(:agent, account: account, user: user) }
    subject { described_class.new(account_user, lead) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_action(:destroy) }

    context "on their own lead" do
      before { lead.lead_agents.create!(agent: agent) }

      it { is_expected.to permit_actions(%i[show update]) }
    end

    context "on another agent's lead" do
      it { is_expected.to forbid_actions(%i[show update]) }
    end
  end

  describe "Scope" do
    let!(:own_lead) { create(:lead, account: account) }
    let!(:other_lead) { create(:lead, account: account) }
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.account_users.first }
    let(:agent) { create(:agent, account: account, user: user) }

    before { own_lead.lead_agents.create!(agent: agent) }

    it "returns only the agent's leads for agents" do
      scope = described_class::Scope.new(account_user, account.leads).resolve
      expect(scope).to include(own_lead)
      expect(scope).not_to include(other_lead)
    end

    it "returns all leads for managers" do
      manager_au = create(:account_user, :manager, account: account)
      scope = described_class::Scope.new(manager_au, account.leads).resolve
      expect(scope).to include(own_lead, other_lead)
    end
  end
end
