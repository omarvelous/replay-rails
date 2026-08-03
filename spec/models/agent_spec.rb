require "rails_helper"

RSpec.describe Agent, type: :model do
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
  end
end
