require "rails_helper"

RSpec.describe PlaylistAd, type: :model do
  subject(:playlist_ad) { build(:playlist_ad) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:position) }
    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:duration).is_greater_than(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:playlist) }
    it { is_expected.to belong_to(:ad) }
  end
end
