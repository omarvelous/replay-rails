require "rails_helper"

RSpec.describe BrandAd, type: :model do
  describe "associations" do
    it "has one ad as adable" do
      brand_ad = create(:brand_ad)
      ad = create(:ad, adable: brand_ad)
      expect(brand_ad.ad).to eq(ad)
    end
  end

  describe "constants" do
    it "defines LAYOUTS" do
      expect(BrandAd::LAYOUTS).to eq(%w[hero minimal])
    end
  end

  describe "#default_headline" do
    it "returns nil" do
      brand_ad = build(:brand_ad)
      expect(brand_ad.default_headline).to be_nil
    end
  end
end
