require "rails_helper"

RSpec.describe Screen, type: :model do
  subject(:screen) { build(:screen) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:orientation).in_array(%w[landscape portrait]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:site) }
    it { is_expected.to have_many(:screen_playlists).dependent(:destroy) }
    it { is_expected.to have_many(:playlists).through(:screen_playlists) }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }

    describe ".search" do
      it "searches by name case-insensitively" do
        match = create(:screen, site: site, name: "Window Display")
        create(:screen, site: site, name: "Gallery Entrance")
        expect(Screen.search("window")).to eq([ match ])
      end
    end

    describe ".live" do
      it "returns screens with active screen_playlists" do
        live_screen = create(:screen, site: site)
        idle_screen = create(:screen, site: site, name: "Idle")
        playlist = create(:playlist, account: account, status: "published")
        create(:screen_playlist, screen: live_screen, playlist: playlist, active: true)

        expect(Screen.live).to include(live_screen)
        expect(Screen.live).not_to include(idle_screen)
      end
    end

    describe ".idle" do
      it "returns screens without active screen_playlists" do
        live_screen = create(:screen, site: site)
        idle_screen = create(:screen, site: site, name: "Idle")
        playlist = create(:playlist, account: account, status: "published")
        create(:screen_playlist, screen: live_screen, playlist: playlist, active: true)

        expect(Screen.idle).to include(idle_screen)
        expect(Screen.idle).not_to include(live_screen)
      end
    end
  end
end
