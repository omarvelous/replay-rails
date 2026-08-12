require "rails_helper"

RSpec.describe BrandAd, type: :model do
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
