require "rails_helper"

RSpec.describe LeadAgentPolicy do
  let(:account) { create(:account) }
  let(:lead_agent) { create(:lead_agent) }

  context "as a manager" do
    let(:account_user) { create(:account_user, :manager, account: account) }
    subject { described_class.new(account_user, lead_agent) }

    it { is_expected.to permit_actions(%i[new create]) }
  end

  context "as an agent" do
    let(:account_user) { create(:account_user, :agent, account: account) }
    subject { described_class.new(account_user, lead_agent) }

    it { is_expected.to forbid_actions(%i[new create]) }
  end
end
