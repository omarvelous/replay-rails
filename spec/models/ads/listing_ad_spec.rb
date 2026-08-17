require "rails_helper"

RSpec.describe Ads::ListingAd do
  subject(:listing_ad) { build(:listing_ad) }

  describe "associations" do
    it { is_expected.to belong_to(:listing) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:listing) }
    it { is_expected.to validate_inclusion_of(:badge).in_array(Ads::ListingAd::BADGES) }

    context "when badge is open_house" do
      subject(:listing_ad) { build(:listing_ad, :open_house, event_date: nil, event_start_time: nil) }

      it { is_expected.to validate_presence_of(:event_date) }
      it { is_expected.to validate_presence_of(:event_start_time) }
    end

    context "when badge is price_reduction" do
      subject(:listing_ad) { build(:listing_ad, :price_reduction, original_price: nil) }

      it { is_expected.to validate_presence_of(:original_price) }
    end

    context "when badge is just_sold" do
      subject(:listing_ad) { build(:listing_ad, :just_sold, sold_price: nil) }

      it { is_expected.to validate_presence_of(:sold_price) }
    end

    context "when badge is just_listed" do
      it "does not require event or price fields" do
        listing_ad = build(:listing_ad, badge: "just_listed")
        expect(listing_ad).to be_valid
      end
    end
  end

  describe "constants" do
    it "defines LAYOUTS" do
      expect(Ads::ListingAd::LAYOUTS).to eq(%w[hero split minimal stat_grid])
    end

    it "defines BADGES" do
      expect(Ads::ListingAd::BADGES).to eq(%w[just_listed open_house just_sold price_reduction coming_soon])
    end
  end

  describe "#badge_label" do
    it "returns the human-readable label for the badge" do
      listing_ad = build(:listing_ad, badge: "open_house")
      expect(listing_ad.badge_label).to eq("Open House")
    end
  end

  describe "#default_headline" do
    it "returns the badge label" do
      listing_ad = build(:listing_ad, badge: "just_sold")
      expect(listing_ad.default_headline).to eq("Just Sold")
    end
  end

  describe "badge predicates" do
    it { expect(build(:listing_ad, badge: "open_house")).to be_open_house }
    it { expect(build(:listing_ad, badge: "just_sold")).to be_just_sold }
    it { expect(build(:listing_ad, badge: "price_reduction")).to be_price_reduction }
    it { expect(build(:listing_ad, badge: "coming_soon")).to be_coming_soon }
    it { expect(build(:listing_ad, badge: "just_listed")).to be_just_listed }
  end
end
