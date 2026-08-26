require "rails_helper"

RSpec.describe ListingPolicy do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }

  context "as an owner" do
    let(:account_user) { create(:account_user, account: account, role: "owner") }
    subject { described_class.new(account_user, listing) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as a manager" do
    let(:account_user) { create(:account_user, :manager, account: account) }
    subject { described_class.new(account_user, listing) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as an agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.account_users.first }
    let(:agent) { create(:agent, account: account, user: user) }
    subject { described_class.new(account_user, listing) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }

    context "on their own listing" do
      before { create(:listing_agent, listing: listing, agent: agent) }

      it { is_expected.to permit_action(:show) }
    end

    context "on another agent's listing" do
      it { is_expected.to forbid_action(:show) }
    end
  end

  describe "Scope" do
    let!(:own_listing) { create(:listing, account: account) }
    let!(:other_listing) { create(:listing, account: account) }
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.account_users.first }
    let(:agent) { create(:agent, account: account, user: user) }

    before { create(:listing_agent, listing: own_listing, agent: agent) }

    it "returns only the agent's listings for agents" do
      scope = described_class::Scope.new(account_user, account.listings).resolve
      expect(scope).to include(own_listing)
      expect(scope).not_to include(other_listing)
    end

    it "returns all listings for managers" do
      manager_au = create(:account_user, :manager, account: account)
      scope = described_class::Scope.new(manager_au, account.listings).resolve
      expect(scope).to include(own_listing, other_listing)
    end
  end
end
