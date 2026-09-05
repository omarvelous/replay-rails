require "rails_helper"

RSpec.describe ScreenContent do
  describe "associations" do
    it { is_expected.to belong_to(:screen) }
    it { is_expected.to belong_to(:contentable) }
  end

  describe "delegated_type" do
    it "supports Playlist as contentable" do
      sc = create(:screen_content)
      expect(sc).to be_playlist
      expect(sc.contentable).to be_a(Playlist)
    end

    it "supports Experience as contentable" do
      sc = create(:screen_content, :with_experience)
      expect(sc).to be_experience
      expect(sc.contentable).to be_a(Experience)
    end
  end

  describe "validations" do
    it "allows only one active content per screen" do
      screen = create(:screen)
      create(:screen_content, screen: screen, active: true)
      duplicate = build(:screen_content, screen: screen, active: true)
      expect(duplicate).not_to be_valid
    end

    it "allows multiple inactive contents on the same screen" do
      screen = create(:screen)
      create(:screen_content, screen: screen, active: false)
      second = build(:screen_content, screen: screen, active: false)
      expect(second).to be_valid
    end
  end
end
