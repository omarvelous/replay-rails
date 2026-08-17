require "rails_helper"

RSpec.describe Agent do
  subject(:agent) { build(:agent) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:listing_agents).dependent(:destroy) }
    it { is_expected.to have_many(:listings).through(:listing_agents) }

    it "has one attached photo" do
      expect(described_class.new.photo).not_to be_attached
    end
  end

  describe "photo attachment" do
    it "attaches a photo" do
      agent = create(:agent)
      agent.photo.attach(io: StringIO.new("fake"), filename: "headshot.jpg", content_type: "image/jpeg")
      expect(agent.photo).to be_attached
    end
  end
end
