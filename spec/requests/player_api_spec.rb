require "rails_helper"

RSpec.describe "PlayerApi", type: :request do
  describe "POST /player/register" do
    it "creates a player and returns a pairing code (JSON)" do
      expect {
        post "/player/register", as: :json
      }.to change(Player, :count).by(1)

      body = response.parsed_body
      expect(body["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(body["token"]).to be_present
      expect(body["expires_in"]).to eq(600)
    end

    it "renders the pairing view (HTML)" do
      post "/player/register"
      expect(response).to be_successful
      expect(response.body).to include("Pair this screen")
    end
  end

  describe "GET /player/status" do
    let(:player) { create(:player) }

    it "returns paired: false when not paired" do
      get "/player/status", params: { code: player.pairing_code }
      expect(response.parsed_body["paired"]).to be false
    end

    it "returns 404 after pairing clears the code" do
      code = player.pairing_code
      screen = create(:screen)
      screen.pair_player!(player)

      get "/player/status", params: { code: code }
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unknown code" do
      get "/player/status", params: { code: "XXXXXX" }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /player/play" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }
    let(:player) { create(:player) }

    before { screen.pair_player!(player) }

    it "returns 401 without a token" do
      get "/player/play"
      expect(response).to have_http_status(:unauthorized)
    end

    it "renders the playlist when one is assigned" do
      playlist = create(:playlist, account: account, status: "published")
      ad = create(:ad, account: account, headline: "Test Ad")
      create(:playlist_ad, playlist: playlist, ad: ad, position: 1, duration: 10)
      create(:screen_playlist, screen: screen, playlist: playlist, active: true)

      get "/player/play", headers: { "Authorization" => "Bearer #{player.token}" }
      expect(response).to be_successful
    end

    it "renders idle when no playlist assigned" do
      get "/player/play", headers: { "Authorization" => "Bearer #{player.token}" }
      expect(response).to be_successful
      expect(response.body).to include("No content assigned")
    end

    it "renders unpaired when player has no screen" do
      unpaired_player = create(:player)
      get "/player/play", headers: { "Authorization" => "Bearer #{unpaired_player.token}" }
      expect(response).to be_successful
      expect(response.body).to include("not paired")
    end
  end

  describe "POST /player/heartbeat" do
    let(:player) { create(:player) }
    let(:screen) { create(:screen) }

    before { screen.pair_player!(player) }

    it "returns 401 without a token" do
      post "/player/heartbeat"
      expect(response).to have_http_status(:unauthorized)
    end

    it "updates last_heartbeat_at and device info" do
      post "/player/heartbeat", headers: { "Authorization" => "Bearer #{player.token}" }
      expect(response).to be_successful

      player.reload
      expect(player.last_heartbeat_at).to be_within(5.seconds).of(Time.current)
      expect(player.ip_address).to be_present
    end
  end
end
