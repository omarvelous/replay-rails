require "rails_helper"

RSpec.describe "Api::Players::Impressions" do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:player) { create(:player) }
  let(:playlist) { create(:playlist, account: account, status: "published") }
  let(:ad) { create(:ad, account: account) }

  before do
    host! "api.replay.localhost"
    screen.pair_player!(player)
  end

  describe "POST /players/:token/impressions" do
    it "creates an impression with all snapshot fields" do
      post "/players/#{player.token}/impressions",
        params: { ad_id: ad.id, playlist_id: playlist.id, position: 2, duration: 15 },
        as: :json

      expect(response).to have_http_status(:created)

      impression = Impression.last
      expect(impression.ad).to eq(ad)
      expect(impression.screen).to eq(screen)
      expect(impression.player).to eq(player)
      expect(impression.site).to eq(site)
      expect(impression.playlist).to eq(playlist)
      expect(impression.account).to eq(account)
      expect(impression.position).to eq(2)
      expect(impression.duration).to eq(15)
    end

    it "works without a playlist_id" do
      post "/players/#{player.token}/impressions",
        params: { ad_id: ad.id, position: 1, duration: 10 },
        as: :json

      expect(response).to have_http_status(:created)
      expect(Impression.last.playlist).to be_nil
    end

    it "returns 401 for invalid token" do
      post "/players/invalid/impressions",
        params: { ad_id: ad.id },
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
