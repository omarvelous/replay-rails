require "rails_helper"

RSpec.describe Listing do
  subject(:listing) { build(:listing) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active pending sold]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }

    it "has many attached photos" do
      expect(described_class.new.photos).to be_empty
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
