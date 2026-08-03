require "rails_helper"

RSpec.describe Playlist, type: :model do
  subject(:playlist) { build(:playlist) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[draft published archived]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:playlist_ads).dependent(:destroy) }
    it { is_expected.to have_many(:ads).through(:playlist_ads) }
  end
end
