require "rails_helper"

RSpec.describe LeadPolicy do
  let(:account) { create(:account) }
  let(:lead) { create(:lead, account: account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { described_class.new(lead, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(lead, user: user, account: account) }

    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:agent) { create(:agent, account: account, user: user) }
    let(:policy) { described_class.new(lead, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).not_to permit(:destroy?) }

    context "when viewing their own lead" do
      before { lead.lead_agents.create!(agent: agent) }

      it { expect(policy).to permit(:show?) }
      it { expect(policy).to permit(:update?) }
    end

    context "when viewing another agent's lead" do
      it { expect(policy).not_to permit(:show?) }
      it { expect(policy).not_to permit(:update?) }
    end
  end

  describe "scope" do
    let!(:own_lead) { create(:lead, account: account) }
    let!(:other_lead) { create(:lead, account: account) }
    let(:user) { create(:user, account: account, role: "agent") }
    let(:agent) { create(:agent, account: account, user: user) }

    before { own_lead.lead_agents.create!(agent: agent) }

    it "returns only the agent's leads for agents" do
      scope = described_class.new(own_lead, user: user, account: account)
                             .apply_scope(Lead.all, type: :active_record_relation)
      expect(scope).to include(own_lead)
      expect(scope).not_to include(other_lead)
    end

    it "returns all leads for managers" do
      manager = create(:user, account: account, role: "manager")
      scope = described_class.new(own_lead, user: manager, account: account)
                             .apply_scope(Lead.all, type: :active_record_relation)
      expect(scope).to include(own_lead, other_lead)
    end
  end
end
