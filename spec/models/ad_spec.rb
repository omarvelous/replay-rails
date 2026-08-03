require "rails_helper"

RSpec.describe Ad, type: :model do
  subject(:ad) { build(:ad) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:headline) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:listing).optional }
  end
end
