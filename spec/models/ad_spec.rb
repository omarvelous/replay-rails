require "rails_helper"

RSpec.describe Ad do
  subject(:ad) { build(:ad) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:playlist_ads).dependent(:destroy) }
    it { is_expected.to have_many(:playlists).through(:playlist_ads) }
    it { is_expected.to have_many(:collection_ad_ads).dependent(:restrict_with_error) }

    it "has one attached image" do
      expect(described_class.new.image).not_to be_attached
    end
  end

  describe "image attachment" do
    it "attaches an image" do
      ad = create(:ad)
      ad.image.attach(io: StringIO.new("fake"), filename: "test.jpg", content_type: "image/jpeg")
      expect(ad.image).to be_attached
    end
  end

  describe "delegated type" do
    it "delegates to adable" do
      listing_ad = create(:listing_ad)
      ad = create(:ad, adable: listing_ad)
      expect(ad).to be_ads_listing_ad
      expect(ad.adable).to eq(listing_ad)
    end

    it "provides adable_name" do
      ad = build(:ad, adable: build(:brand_ad))
      expect(ad.adable_name).to eq("ads_brand_ad")
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:headline) }
    it { is_expected.to validate_inclusion_of(:theme).in_array(Ad::THEMES) }

    it "validates layout is in adable's LAYOUTS" do
      listing_ad = build(:listing_ad)
      ad = build(:ad, adable: listing_ad, layout: "profile")
      expect(ad).not_to be_valid
      expect(ad.errors[:layout]).to be_present
    end

    it "accepts a valid layout for the adable type" do
      listing_ad = build(:listing_ad)
      ad = build(:ad, adable: listing_ad, layout: "hero")
      expect(ad).to be_valid
    end
  end

  describe "#allowed_layouts" do
    it "delegates to the adable class constant" do
      ad = build(:ad, adable: build(:listing_ad))
      expect(ad.allowed_layouts).to eq(Ads::ListingAd::LAYOUTS)
    end

    it "returns hero as default when adable is nil" do
      ad = build(:ad)
      ad.adable = nil
      expect(ad.allowed_layouts).to eq(%w[hero])
    end
  end

  describe "#apply_defaults" do
    it "sets headline from adable default" do
      listing_ad = build(:listing_ad, badge: "open_house")
      ad = build(:ad, adable: listing_ad, headline: nil)
      ad.apply_defaults
      expect(ad.headline).to eq("Open House")
    end

    it "sets layout to first allowed layout when blank" do
      ad = build(:ad, adable: build(:listing_ad), layout: nil)
      ad.apply_defaults
      expect(ad.layout).to eq("hero")
    end

    it "sets theme to dark when blank" do
      ad = build(:ad, adable: build(:listing_ad), theme: nil)
      ad.apply_defaults
      expect(ad.theme).to eq("dark")
    end

    it "does not override existing values" do
      ad = build(:ad, adable: build(:listing_ad), headline: "Custom", layout: "split", theme: "light")
      ad.apply_defaults
      expect(ad.headline).to eq("Custom")
      expect(ad.layout).to eq("split")
      expect(ad.theme).to eq("light")
    end
  end

  describe "deletion protection" do
    it "cannot be deleted when referenced by a collection" do
      collection_ad = create(:collection_ad)
      ad = create(:ad, adable: create(:listing_ad))
      create(:collection_ad_ad, collection_ad: collection_ad, ad: ad)

      expect(ad.destroy).to be false
      expect(ad.errors[:base]).to be_present
    end
  end

  describe "search scope" do
    it "searches by headline" do
      ad1 = create(:ad, headline: "Just Listed on Maple")
      create(:ad, headline: "Brand Campaign")
      expect(described_class.search("Maple")).to eq([ ad1 ])
    end
  end
end
