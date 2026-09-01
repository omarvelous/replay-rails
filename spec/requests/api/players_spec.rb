require "rails_helper"

RSpec.describe "Api::Players" do
  before { host! "api.replay.localhost" }

  describe "POST /players" do
    it "registers a player and returns JSON" do
      expect {
        post "/players", as: :json
      }.to change(Player, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["token"]).to be_present
      expect(response.parsed_body["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(response.parsed_body["expires_in"]).to eq(600)
    end
  end

  describe "GET /players/:token" do
    let(:player) { create(:player) }

    it "returns paired: false when not paired" do
      get "/players/#{player.token}"
      expect(response).to be_successful
      expect(response.parsed_body["paired"]).to be false
      expect(response.parsed_body["screen_id"]).to be_nil
    end

    it "returns paired: true with screen_id when paired" do
      screen = create(:screen)
      screen.pair_player!(player)

      get "/players/#{player.token}"
      expect(response).to be_successful
      expect(response.parsed_body["paired"]).to be true
      expect(response.parsed_body["screen_id"]).to eq(screen.id)
    end

    it "returns 401 for invalid token" do
      get "/players/invalid"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /players/:token/pairing_code" do
    let(:player) { create(:player) }

    it "returns the existing code if still valid" do
      existing_code = player.pairing_code

      post "/players/#{player.token}/pairing_code", as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["pairing_code"]).to eq(existing_code)
      expect(response.parsed_body["expires_in"]).to be_between(1, 600)
    end

    it "generates a new code if the current one has expired" do
      player.update!(pairing_code_expires_at: 1.minute.ago)
      old_code = player.pairing_code

      post "/players/#{player.token}/pairing_code", as: :json

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(response.parsed_body["pairing_code"]).not_to eq(old_code)
      expect(response.parsed_body["expires_in"]).to eq(600)
    end

    it "does not create a new player" do
      player # ensure created

      expect {
        post "/players/#{player.token}/pairing_code", as: :json
      }.not_to change(Player, :count)
    end

    it "returns 401 for invalid token" do
      post "/players/invalid/pairing_code", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
