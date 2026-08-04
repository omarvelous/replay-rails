require "rails_helper"

RSpec.describe "Screen Playlist", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:playlist) { create(:playlist, account: account, status: "published") }

  before { sign_in(user) }

  describe "GET /sites/:site_id/screens/:screen_id/playlist/new" do
    it "returns a successful response" do
      get new_site_screen_playlist_path(site, screen)
      expect(response).to be_successful
    end
  end

  describe "POST /sites/:site_id/screens/:screen_id/playlist" do
    it "assigns a playlist to the screen" do
      expect {
        post site_screen_playlist_path(site, screen), params: { screen_playlist: { playlist_id: playlist.id } }
      }.to change(screen.screen_playlists, :count).by(1)
    end

    it "redirects to the screen" do
      post site_screen_playlist_path(site, screen), params: { screen_playlist: { playlist_id: playlist.id } }
      expect(response).to redirect_to(site_screen_path(site, screen))
    end

    it "replaces an existing assignment" do
      old_playlist = create(:playlist, account: account, status: "published")
      create(:screen_playlist, screen: screen, playlist: old_playlist)

      post site_screen_playlist_path(site, screen), params: { screen_playlist: { playlist_id: playlist.id } }
      expect(screen.screen_playlists.where(active: true).count).to eq(1)
      expect(screen.screen_playlists.find_by(active: true).playlist).to eq(playlist)
    end
  end

  describe "DELETE /sites/:site_id/screens/:screen_id/playlist" do
    it "removes the playlist from the screen" do
      create(:screen_playlist, screen: screen, playlist: playlist)
      expect {
        delete site_screen_playlist_path(site, screen)
      }.to change(screen.screen_playlists, :count).by(-1)
    end

    it "redirects to the screen" do
      create(:screen_playlist, screen: screen, playlist: playlist)
      delete site_screen_playlist_path(site, screen)
      expect(response).to redirect_to(site_screen_path(site, screen))
    end
  end

  describe "screen show page" do
    it "shows the assigned playlist" do
      create(:screen_playlist, screen: screen, playlist: playlist)
      get site_screen_path(site, screen)
      expect(response.body).to include(playlist.name)
    end

    it "shows assign link when no playlist" do
      get site_screen_path(site, screen)
      expect(response.body).to include("Assign Playlist")
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's screen" do
      other_site = create(:site)
      other_screen = create(:screen, site: other_site)
      get new_site_screen_playlist_path(other_site, other_screen)
      expect(response).to have_http_status(:not_found)
    end
  end
end
