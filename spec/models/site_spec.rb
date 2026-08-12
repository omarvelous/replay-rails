require "rails_helper"

RSpec.describe Site, type: :model do
  subject(:site) { build(:site) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:screens).dependent(:destroy) }

    it "has one attached photo" do
      expect(Site.new.photo).not_to be_attached
    end
  end

  describe "photo attachment" do
    it "attaches a photo" do
      site = create(:site)
      site.photo.attach(io: StringIO.new("fake"), filename: "office.jpg", content_type: "image/jpeg")
      expect(site.photo).to be_attached
    end
  end
end
