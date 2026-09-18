require "rails_helper"

RSpec.describe "Play::Manifests" do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:player) { create(:player) }

  before do
    host! "play.replay.localhost"
    pair_player!(screen, player)
    sign_in_player(player)
  end

  describe "GET /player/manifest" do
    it "returns null content when no content assigned" do
      get "/player/manifest"
      expect(response).to be_successful
      expect(response.parsed_body["data"]["content"]).to be_nil
    end

    it "returns manifest JSON when content is assigned" do
      playlist = create(:playlist, account: account, status: "published")
      ad = create(:ad, account: account, headline: "Test Ad")
      create(:playlist_ad, playlist: playlist, ad: ad, position: 1, duration: 10)
      create(:screen_content, screen: screen, contentable: playlist, active: true)

      get "/player/manifest"
      expect(response).to be_successful
      json = response.parsed_body
      expect(json["contentable"]["type"]).to eq("Playlist")
    end

    it "redirects to pairing without session" do
      PlayerSession.last.revoke!
      get "/player/manifest"
      expect(response).to redirect_to(new_player_path)
    end
  end
end
