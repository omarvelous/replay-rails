require "rails_helper"

RSpec.describe "Api::Players::Manifests" do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:player) { create(:player) }
  let(:playlist) { create(:playlist, account: account, status: "published") }

  before do
    host! "api.replay.localhost"
    screen.pair_player!(player)
  end

  describe "GET /players/:token/manifest" do
    context "with no content assigned" do
      it "returns null content" do
        get "/players/#{player.token}/manifest"
        expect(response).to be_successful
        expect(parsed_json["content"]).to be_nil
      end
    end

    context "with a playlist assigned" do
      before do
        ad = create(:ad, account: account, headline: "Test Ad")
        create(:playlist_ad, playlist: playlist, ad: ad, position: 1, duration: 10)
        create(:screen_content, screen: screen, contentable: playlist, active: true)
      end

      it "returns the manifest JSON with dependency tree" do
        get "/players/#{player.token}/manifest"
        expect(response).to be_successful
        json = parsed_json
        expect(json["deploy"]).to be_present
        expect(json["screen_content"]["id"]).to be_present
        expect(json["contentable"]["type"]).to eq("Playlist")
        expect(json["contentable"]["playlist_ads"]).to be_an(Array)
      end

      it "returns an ETag header" do
        get "/players/#{player.token}/manifest"
        expect(response.headers["ETag"]).to be_present
      end

      it "returns 304 when content unchanged" do
        get "/players/#{player.token}/manifest"
        etag = response.headers["ETag"]

        get "/players/#{player.token}/manifest", headers: { "If-None-Match" => etag }
        expect(response).to have_http_status(:not_modified)
      end

      it "returns 200 with new ETag when content changes" do
        get "/players/#{player.token}/manifest"
        etag = response.headers["ETag"]

        # Change ad headline → manifest should differ
        # Force a different updated_at by touching with a new timestamp
        ad = Ad.last
        ad.update_columns(headline: "Updated Headline", updated_at: 1.minute.from_now)

        get "/players/#{player.token}/manifest"
        new_etag = response.headers["ETag"]
        expect(new_etag).not_to eq(etag)
      end
    end

    context "with an experience assigned" do
      before do
        listing = create(:listing, account: account)
        listing_exp = create(:listing_experience, listing: listing)
        experience = create(:experience, account: account, experienceable: listing_exp)
        create(:screen_content, screen: screen, contentable: experience, active: true)
      end

      it "returns the manifest with experience dependency tree including listing" do
        get "/players/#{player.token}/manifest"
        json = parsed_json
        expect(json["contentable"]["type"]).to eq("Experience")
        experienceable = json["contentable"]["experienceable"]
        expect(experienceable).to be_present
        expect(experienceable["type"]).to eq("Experiences::ListingExperience")
        expect(experienceable["listing"]).to be_present
        expect(experienceable["listing"]["id"]).to be_present
      end
    end

    it "returns 401 for invalid token" do
      get "/players/invalid/manifest"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  private

  def parsed_json
    JSON.parse(response.body)
  end
end
