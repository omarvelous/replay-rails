require "rails_helper"

RSpec.describe ListingAgent, type: :model do
  subject(:listing_agent) { build(:listing_agent) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:role) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:listing) }
    it { is_expected.to belong_to(:agent) }
  end
end
