require "rails_helper"

RSpec.describe "App::Pairings" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:site) { create(:site, account: account) }

  before { sign_in(user) }

  describe "GET /pair" do
    it "returns a successful response" do
      get pair_path
      expect(response).to be_successful
    end

    it "lists screens for the current account" do
      screen = create(:screen, site: site, name: "Front Window")
      get pair_path
      expect(response.body).to include("Front Window")
    end

    it "pre-fills the code from params" do
      get pair_path(code: "A7B3K2")
      expect(response.body).to include("A7B3K2")
    end

    it "requires authentication" do
      get pair_path, headers: { "Cookie" => "" }
      expect(response).to redirect_to(new_session_url(subdomain: "app"))
    end
  end

  describe "POST /pair" do
    let(:screen) { create(:screen, site: site) }
    let(:player) { create(:player) }

    it "pairs the player to the selected screen" do
      post pair_path, params: { screen_id: screen.id, code: player.pairing_code }
      expect(screen.reload.player).to eq(player)
    end

    it "redirects to the screen page on success" do
      post pair_path, params: { screen_id: screen.id, code: player.pairing_code }
      expect(response).to redirect_to(screen_path(screen))
    end

    it "shows an error for an invalid code" do
      post pair_path, params: { screen_id: screen.id, code: "INVALID" }
      expect(response.body).to include("Invalid")
    end

    it "shows an error for an expired code" do
      player.update!(pairing_code_expires_at: 1.hour.ago)
      post pair_path, params: { screen_id: screen.id, code: player.pairing_code }
      expect(response.body).to include("expired")
    end
  end
end
