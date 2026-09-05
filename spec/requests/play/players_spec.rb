require "rails_helper"

RSpec.describe "Play::Players" do
  before { host! "play.replay.localhost" }

  describe "GET /players/new (pairing screen)" do
    it "returns a successful HTML response" do
      get "/players/new"
      expect(response).to be_successful
      expect(response.body).to include("Pair this screen")
    end
  end

  describe "GET /players/:token (playback)" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }
    let(:player) { create(:player) }

    before { screen.pair_player!(player) }

    it "renders the playlist when one is assigned" do
      playlist = create(:playlist, account: account, status: "published")
      ad = create(:ad, account: account, headline: "Test Ad")
      create(:playlist_ad, playlist: playlist, ad: ad, position: 1, duration: 10)
      create(:screen_content, screen: screen, contentable: playlist, active: true)

      get "/players/#{player.token}"
      expect(response).to be_successful
    end

    it "renders idle when no playlist assigned" do
      get "/players/#{player.token}"
      expect(response).to be_successful
      expect(response.body).to include("No content assigned")
    end

    it "renders unpaired when player has no screen" do
      unpaired_player = create(:player)
      get "/players/#{unpaired_player.token}"
      expect(response).to be_successful
      expect(response.body).to include("not paired")
    end

    it "redirects to pairing for invalid token" do
      get "/players/invalid"
      expect(response).to redirect_to(new_player_path)
    end
  end
end
