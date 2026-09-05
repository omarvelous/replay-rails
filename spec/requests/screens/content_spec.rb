require "rails_helper"

RSpec.describe "Screen Content" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:playlist) { create(:playlist, account: account, status: "published") }

  before { sign_in(user) }

  describe "GET /screens/:screen_id/screen_content/new" do
    it "returns a successful response" do
      get new_screen_screen_content_path(screen)
      expect(response).to be_successful
    end
  end

  describe "POST /screens/:screen_id/screen_content" do
    it "assigns a playlist to the screen" do
      expect {
        post screen_screen_content_path(screen), params: { screen_content: { contentable_type: "Playlist", contentable_id: playlist.id } }
      }.to change(screen.screen_contents, :count).by(1)
    end

    it "redirects to the screen" do
      post screen_screen_content_path(screen), params: { screen_content: { contentable_type: "Playlist", contentable_id: playlist.id } }
      expect(response).to redirect_to(screen_path(screen))
    end

    it "replaces an existing assignment" do
      old_playlist = create(:playlist, account: account, status: "published")
      create(:screen_content, screen: screen, contentable: old_playlist)

      post screen_screen_content_path(screen), params: { screen_content: { contentable_type: "Playlist", contentable_id: playlist.id } }
      expect(screen.screen_contents.where(active: true).count).to eq(1)
      expect(screen.screen_contents.find_by(active: true).contentable).to eq(playlist)
    end

    it "assigns an experience to the screen" do
      experience = create(:experience, account: account)
      expect {
        post screen_screen_content_path(screen), params: { screen_content: { contentable_type: "Experience", contentable_id: experience.id } }
      }.to change(screen.screen_contents, :count).by(1)
      expect(screen.active_content).to eq(experience)
    end
  end

  describe "DELETE /screens/:screen_id/screen_content" do
    it "removes the content from the screen" do
      create(:screen_content, screen: screen, contentable: playlist)
      expect {
        delete screen_screen_content_path(screen)
      }.to change(screen.screen_contents, :count).by(-1)
    end

    it "redirects to the screen" do
      create(:screen_content, screen: screen, contentable: playlist)
      delete screen_screen_content_path(screen)
      expect(response).to redirect_to(screen_path(screen))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's screen" do
      other_screen = create(:screen)
      get new_screen_screen_content_path(other_screen)
      expect(response).to have_http_status(:not_found)
    end
  end
end
