require "rails_helper"

RSpec.describe ListingAgent do
  subject(:listing_agent) { build(:listing_agent) }

  describe "validations" do
    it { is_expected.to validate_inclusion_of(:role).in_array(ListingAgent::ROLES) }

    it "is invalid when listing and agent belong to different accounts" do
      listing = create(:listing)
      agent = create(:agent)
      la = build(:listing_agent, listing: listing, agent: agent)
      expect(la).not_to be_valid
      expect(la.errors[:agent]).to include("not found")
    end

    it "is valid when listing and agent belong to the same account" do
      account = create(:account)
      listing = create(:listing, account: account)
      agent = create(:agent, account: account)
      la = build(:listing_agent, listing: listing, agent: agent)
      expect(la).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to belong_to(:agent) }
  end

  describe ".primary" do
    it "returns listing agents with primary_at set, most recent first" do
      account = create(:account)
      listing = create(:listing, account: account)
      agent_a = create(:agent, account: account)
      agent_b = create(:agent, account: account)

      la_a = create(:listing_agent, listing: listing, agent: agent_a, primary_at: 2.days.ago)
      la_b = create(:listing_agent, listing: listing, agent: agent_b, primary_at: 1.day.ago)
      create(:listing_agent, listing: listing, agent: create(:agent, account: account), primary_at: nil)

      expect(described_class.primary).to eq([ la_b, la_a ])
    end
  end
end
