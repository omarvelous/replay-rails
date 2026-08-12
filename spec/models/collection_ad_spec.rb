require "rails_helper"

RSpec.describe CollectionAd, type: :model do
  subject(:collection_ad) { build(:collection_ad) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:collection_title) }
  end

  describe "constants" do
    it "defines LAYOUTS" do
      expect(CollectionAd::LAYOUTS).to eq(%w[grid])
    end
  end

  describe "#default_headline" do
    it "returns the collection title" do
      collection_ad = build(:collection_ad, collection_title: "New Listings")
      expect(collection_ad.default_headline).to eq("New Listings")
    end
  end
end
