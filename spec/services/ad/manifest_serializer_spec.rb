require "rails_helper"

RSpec.describe Ad::ManifestSerializer do
  let(:account) { create(:account) }

  before { ActsAsTenant.current_tenant = account }

  let(:listing) { create(:listing, account: account) }
  let(:listing_ad) { create(:listing_ad, listing: listing) }
  let(:ad) { create(:ad, account: account, adable: listing_ad) }

  subject(:json) { described_class.new(ad).as_json }

  describe "#as_json" do
    it "includes top-level ad fields" do
      expect(json).to include(
        pid: ad.public_id,
        headline: ad.headline,
        body: ad.body,
        layout: ad.layout,
        theme: ad.theme,
        position: 0,
        duration: 10
      )
    end

    it "accepts custom position and duration" do
      result = described_class.new(ad, position: 3, duration: 20).as_json
      expect(result[:position]).to eq(3)
      expect(result[:duration]).to eq(20)
    end

    it "includes images as an array" do
      expect(json[:images]).to be_an(Array)
    end

    describe "adable" do
      it "includes listing ad fields" do
        adable = json[:adable]
        expect(adable[:type]).to eq("Ads::ListingAd")
        expect(adable[:pid]).to eq(listing_ad.public_id)
        expect(adable[:badge]).to eq(listing_ad.badge)
        expect(adable[:badge_label]).to eq(listing_ad.badge_label)
      end

      it "includes listing data" do
        listing_json = json[:adable][:listing]
        expect(listing_json[:pid]).to eq(listing.public_id)
        expect(listing_json[:address]).to eq(listing.address)
        expect(listing_json[:street]).to eq(listing.street)
        expect(listing_json[:city]).to eq(listing.city)
        expect(listing_json[:state]).to eq(listing.state)
        expect(listing_json[:price]).to eq(listing.price.to_f)
        expect(listing_json[:beds]).to eq(listing.beds)
        expect(listing_json[:baths]).to eq(listing.baths)
        expect(listing_json[:sqft]).to eq(listing.sqft)
      end

      it "includes agent when listing has one" do
        agent = create(:agent, account: account)
        create(:listing_agent, listing: listing, agent: agent, role: "listing_agent", primary_at: Time.current)

        agent_json = json[:adable][:agent]
        expect(agent_json[:pid]).to eq(agent.public_id)
        expect(agent_json[:name]).to eq(agent.name)
        expect(agent_json[:email]).to eq(agent.email)
      end

      it "omits agent when listing has none" do
        expect(json[:adable]).not_to have_key(:agent)
      end
    end
  end
end
