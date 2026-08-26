require "rails_helper"

RSpec.describe ListingPolicy do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { described_class.new(listing, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(listing, user: user, account: account) }

    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:agent) { create(:agent, account: account, user: user) }
    let(:policy) { described_class.new(listing, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }

    context "when viewing their own listing" do
      before { create(:listing_agent, listing: listing, agent: agent) }

      it { expect(policy).to permit(:show?) }
    end

    context "when viewing another agent's listing" do
      it { expect(policy).not_to permit(:show?) }
    end
  end

  describe "scope" do
    let!(:own_listing) { create(:listing, account: account) }
    let!(:other_listing) { create(:listing, account: account) }
    let(:user) { create(:user, account: account, role: "agent") }
    let(:agent) { create(:agent, account: account, user: user) }

    before { create(:listing_agent, listing: own_listing, agent: agent) }

    it "returns only the agent's listings for agents" do
      scope = described_class.new(own_listing, user: user, account: account)
                             .apply_scope(account.listings, type: :active_record_relation)
      expect(scope).to include(own_listing)
      expect(scope).not_to include(other_listing)
    end

    it "returns all listings for managers" do
      manager = create(:user, account: account, role: "manager")
      scope = described_class.new(own_listing, user: manager, account: account)
                             .apply_scope(account.listings, type: :active_record_relation)
      expect(scope).to include(own_listing, other_listing)
    end
  end
end
