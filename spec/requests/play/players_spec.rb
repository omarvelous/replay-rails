require "rails_helper"

RSpec.describe "Play::Players" do
  before { host! "play.replay.localhost" }

  describe "GET /player/new (pairing screen)" do
    it "returns a successful HTML response" do
      get "/player/new"
      expect(response).to be_successful
      expect(response.body).to include("Pair this screen")
    end
  end

  describe "GET /player (playback)" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }
    let(:player) { create(:player) }

    before { pair_player!(screen, player) }

    it "renders the playlist when one is assigned" do
      sign_in_player(player)
      playlist = create(:playlist, account: account, status: "published")
      ad = create(:ad, account: account, headline: "Test Ad")
      create(:playlist_ad, playlist: playlist, ad: ad, position: 1, duration: 10)
      create(:screen_content, screen: screen, contentable: playlist, active: true)

      get "/player"
      expect(response).to be_successful
    end

    it "renders idle when no playlist assigned" do
      sign_in_player(player)
      get "/player"
      expect(response).to be_successful
      expect(response.body).to include("No content assigned")
    end

    it "renders unpaired when player has no screen" do
      unpaired_player = create(:player)
      sign_in_player(unpaired_player)
      get "/player"
      expect(response).to be_successful
      expect(response.body).to include("not paired")
    end

    it "redirects to pairing without cookie" do
      get "/player"
      expect(response).to redirect_to(new_player_path)
    end

    it "authenticates via token param and sets session cookie" do
      new_session = player.player_sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      token = new_session.bearer_token

      get "/player", params: { token: token }
      expect(response).to be_successful
      expect(cookies[:player_session_id]).to be_present
    end

    it "authenticates via token even when stale cookie exists" do
      old_session = player.player_sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      sign_in_player(player)
      old_session.revoke!

      new_session = player.player_sessions.create!(ip_address: "127.0.0.1", user_agent: "RSpec")
      token = new_session.bearer_token

      get "/player", params: { token: token }
      expect(response).to be_successful
    end

    it "ignores invalid token param" do
      get "/player", params: { token: "garbage" }
      expect(response).to redirect_to(new_player_path)
    end
  end
end
