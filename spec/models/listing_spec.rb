require "rails_helper"

RSpec.describe Listing do
  subject(:listing) { build(:listing) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active pending sold]) }
    it { is_expected.to validate_presence_of(:property_type) }
    it { is_expected.to validate_inclusion_of(:property_type).in_array(Listing::PROPERTY_TYPES) }
    it { is_expected.to validate_presence_of(:listing_type) }
    it { is_expected.to validate_inclusion_of(:listing_type).in_array(Listing::LISTING_TYPES) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }

    it "has many attached photos" do
      expect(described_class.new.photos).to be_empty
    end

    it "has many attached floor_plans" do
      expect(described_class.new.floor_plans).to be_empty
    end
  end

  describe "photos attachment" do
    it "attaches multiple photos" do
      listing = create(:listing)
      listing.photos.attach(io: StringIO.new("fake1"), filename: "photo1.jpg", content_type: "image/jpeg")
      listing.photos.attach(io: StringIO.new("fake2"), filename: "photo2.jpg", content_type: "image/jpeg")
      expect(listing.photos.count).to eq(2)
    end
  end

  describe "#primary_agent" do
    it "returns the agent with the most recent primary_at" do
      account = create(:account)
      listing = create(:listing, account: account)
      agent_a = create(:agent, account: account)
      agent_b = create(:agent, account: account)

      create(:listing_agent, listing: listing, agent: agent_a, primary_at: 2.days.ago)
      create(:listing_agent, listing: listing, agent: agent_b, primary_at: 1.day.ago)

      expect(listing.primary_agent).to eq(agent_b)
    end

    it "falls back to the first agent when no primary_at is set" do
      account = create(:account)
      listing = create(:listing, account: account)
      agent = create(:agent, account: account)
      create(:listing_agent, listing: listing, agent: agent, primary_at: nil)

      expect(listing.primary_agent).to eq(agent)
    end

    it "returns nil when no agents are assigned" do
      listing = create(:listing)
      expect(listing.primary_agent).to be_nil
    end
  end

  describe "scopes" do
    describe ".search" do
      it "searches by address case-insensitively" do
        match = create(:listing, address: "350 Fifth Ave")
        create(:listing, address: "20 W 34th St")
        expect(described_class.search("fifth")).to eq([ match ])
      end
    end

    describe ".by_status" do
      it "filters by status" do
        active = create(:listing, status: "active")
        create(:listing, status: "sold")
        expect(described_class.by_status("active")).to eq([ active ])
      end
    end
  end
end
