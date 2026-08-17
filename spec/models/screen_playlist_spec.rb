require "rails_helper"

RSpec.describe ScreenPlaylist do
  subject(:screen_playlist) { build(:screen_playlist) }

  describe "associations" do
    it { is_expected.to belong_to(:screen) }
    it { is_expected.to belong_to(:playlist) }
  end
end
