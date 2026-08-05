require "rails_helper"

RSpec.describe PlaylistAd, type: :model do
  subject(:playlist_ad) { build(:playlist_ad) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:duration) }
    it { is_expected.to validate_numericality_of(:duration).is_greater_than(0) }

    it "is invalid when playlist and ad belong to different accounts" do
      playlist = create(:playlist)
      ad = create(:ad)
      pa = build(:playlist_ad, playlist: playlist, ad: ad)
      expect(pa).not_to be_valid
      expect(pa.errors[:ad]).to include("not found")
    end

    it "is valid when playlist and ad belong to the same account" do
      account = create(:account)
      playlist = create(:playlist, account: account)
      ad = create(:ad, account: account)
      pa = build(:playlist_ad, playlist: playlist, ad: ad)
      expect(pa).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:playlist) }
    it { is_expected.to belong_to(:ad) }
  end
end
