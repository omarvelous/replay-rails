require "rails_helper"

RSpec.describe Ads::CollectionAd do
  subject(:collection_ad) { build(:collection_ad) }

  describe "associations" do
    it { is_expected.to have_many(:collection_ad_ads).dependent(:destroy) }
    it { is_expected.to have_many(:member_ads).through(:collection_ad_ads) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:collection_title) }
  end

  describe "constants" do
    it "defines LAYOUTS" do
      expect(Ads::CollectionAd::LAYOUTS).to eq(%w[grid])
    end
  end

  describe "#default_headline" do
    it "returns the collection title" do
      collection_ad = build(:collection_ad, collection_title: "New Listings")
      expect(collection_ad.default_headline).to eq("New Listings")
    end
  end
end
