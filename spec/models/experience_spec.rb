require "rails_helper"

RSpec.describe Experience do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:experienceable) }
    it { is_expected.to have_many(:screen_contents) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "delegated_type" do
    it "supports ListingExperience" do
      experience = create(:experience)
      expect(experience.experienceable_type).to eq("Experiences::ListingExperience")
      expect(experience.experienceable).to be_a(Experiences::ListingExperience)
    end
  end

  describe "#listing" do
    it "delegates to experienceable" do
      experience = create(:experience)
      expect(experience.listing).to eq(experience.experienceable.listing)
    end
  end

  describe "#default_agent" do
    it "returns nil when no agent assigned" do
      experience = create(:experience)
      expect(experience.default_agent).to be_nil
    end

    it "returns the experienceable's agent when set" do
      account = create(:account)
      agent = create(:agent, account: account)
      listing = create(:listing, account: account)
      listing_exp = create(:listing_experience, listing: listing, agent: agent)
      experience = create(:experience, account: account, experienceable: listing_exp)
      expect(experience.default_agent).to eq(agent)
    end
  end
end
