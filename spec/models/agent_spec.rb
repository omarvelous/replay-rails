require "rails_helper"

RSpec.describe Agent do
  subject(:agent) { build(:agent) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }

    it "validates email uniqueness within account" do
      existing = create(:agent)
      duplicate = build(:agent, account: existing.account, email: existing.email)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "allows same email across different accounts" do
      agent1 = create(:agent, email: "shared@example.com")
      agent2 = build(:agent, email: "shared@example.com")
      expect(agent2).to be_valid
    end
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
