require "rails_helper"

RSpec.describe Listing, type: :model do
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
      expect(Listing.new.photos).to be_empty
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
end
