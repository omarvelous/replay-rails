require "rails_helper"

RSpec.describe Experiences::ListingExperience do
  describe "associations" do
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to belong_to(:agent).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:listing) }
  end

  describe "#default_agent" do
    it "returns the assigned agent when set" do
      account = create(:account)
      agent = create(:agent, account: account)
      listing = create(:listing, account: account)
      listing_exp = create(:listing_experience, listing: listing, agent: agent)
      expect(listing_exp.default_agent).to eq(agent)
    end

    it "falls back to the listing's primary agent" do
      account = create(:account)
      agent = create(:agent, account: account)
      listing = create(:listing, account: account)
      create(:listing_agent, listing: listing, agent: agent)
      listing_exp = create(:listing_experience, listing: listing)
      expect(listing_exp.default_agent).to eq(agent)
    end

    it "returns nil when no agent assigned or on listing" do
      listing_exp = create(:listing_experience)
      expect(listing_exp.default_agent).to be_nil
    end
  end
end
