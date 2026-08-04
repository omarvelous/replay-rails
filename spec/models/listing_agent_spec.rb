require "rails_helper"

RSpec.describe ListingAgent, type: :model do
  subject(:listing_agent) { build(:listing_agent) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:role) }

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
end
