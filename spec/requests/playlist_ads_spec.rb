require "rails_helper"

RSpec.describe "PlaylistAds" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:playlist) { create(:playlist, account: account) }
  let(:ad) { create(:ad, account: account) }

  before { sign_in(user) }

  describe "from playlist context" do
    describe "GET /playlists/:id/playlist_ads/new" do
      it "returns a successful response" do
        get new_playlist_playlist_ad_path(playlist)
        expect(response).to be_successful
      end
    end

    describe "POST /playlists/:id/playlist_ads" do
      it "creates a playlist ad" do
        expect {
          post playlist_playlist_ads_path(playlist), params: { playlist_ad: { ad_id: ad.id, position: 1, duration: 15 } }
        }.to change(PlaylistAd, :count).by(1)
      end

      it "redirects to the playlist" do
        post playlist_playlist_ads_path(playlist), params: { playlist_ad: { ad_id: ad.id, position: 1, duration: 15 } }
        expect(response).to redirect_to(playlist_path(playlist))
      end

      it "returns 422 when ad is missing" do
        post playlist_playlist_ads_path(playlist), params: { playlist_ad: { ad_id: "", position: 1, duration: 10 } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe "GET /playlists/:id/playlist_ads/:id/edit" do
      it "returns a successful response" do
        pa = create(:playlist_ad, playlist: playlist, ad: ad)
        get edit_playlist_playlist_ad_path(playlist, pa)
        expect(response).to be_successful
      end
    end

    describe "PATCH /playlists/:id/playlist_ads/:id" do
      it "updates the playlist ad" do
        pa = create(:playlist_ad, playlist: playlist, ad: ad, duration: 10)
        patch playlist_playlist_ad_path(playlist, pa), params: { playlist_ad: { duration: 20 } }
        expect(pa.reload.duration).to eq(20)
      end
    end

    describe "DELETE /playlists/:id/playlist_ads/:id" do
      it "destroys the playlist ad" do
        pa = create(:playlist_ad, playlist: playlist, ad: ad)
        expect {
          delete playlist_playlist_ad_path(playlist, pa)
        }.to change(PlaylistAd, :count).by(-1)
      end

      it "redirects to the playlist" do
        pa = create(:playlist_ad, playlist: playlist, ad: ad)
        delete playlist_playlist_ad_path(playlist, pa)
        expect(response).to redirect_to(playlist_path(playlist))
      end
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's playlist" do
      other_playlist = create(:playlist)
      get playlist_playlist_ads_path(other_playlist)
      expect(response).to have_http_status(:not_found)
    end
  end
end
