require "rails_helper"

RSpec.describe "Admin Resources" do
  let(:admin) { create(:user, admin: true) }

  before do
    host! "admin.replay.localhost"
    sign_in(admin)
  end

  describe "Accounts" do
    it "GET /accounts" do
      create(:account)
      get admin_accounts_path
      expect(response).to be_successful
    end

    it "GET /accounts/:id" do
      account = create(:account)
      get admin_account_path(account)
      expect(response).to be_successful
    end
  end

  describe "Users" do
    it "GET /users" do
      get admin_users_path
      expect(response).to be_successful
    end

    it "GET /users/:id" do
      get admin_user_path(admin)
      expect(response).to be_successful
    end
  end

  describe "Sites" do
    it "GET /sites" do
      create(:site)
      get admin_sites_path
      expect(response).to be_successful
    end

    it "GET /sites/:id" do
      site = create(:site)
      get admin_site_path(site)
      expect(response).to be_successful
    end
  end

  describe "Players" do
    it "GET /players" do
      create(:player)
      get admin_players_path
      expect(response).to be_successful
    end

    it "GET /players/:id" do
      player = create(:player)
      get admin_player_path(player)
      expect(response).to be_successful
    end
  end

  describe "Screens" do
    it "GET /screens" do
      create(:screen)
      get admin_screens_path
      expect(response).to be_successful
    end

    it "GET /screens/:id" do
      screen = create(:screen)
      get admin_screen_path(screen)
      expect(response).to be_successful
    end
  end

  describe "Listings" do
    it "GET /listings" do
      create(:listing)
      get admin_listings_path
      expect(response).to be_successful
    end

    it "GET /listings/:id" do
      listing = create(:listing)
      get admin_listing_path(listing)
      expect(response).to be_successful
    end
  end

  describe "Agents" do
    it "GET /agents" do
      create(:agent)
      get admin_agents_path
      expect(response).to be_successful
    end

    it "GET /agents/:id" do
      agent = create(:agent)
      get admin_agent_path(agent)
      expect(response).to be_successful
    end
  end

  describe "Ads" do
    it "GET /ads" do
      create(:ad)
      get admin_ads_path
      expect(response).to be_successful
    end

    it "GET /ads/:id" do
      ad = create(:ad)
      get admin_ad_path(ad)
      expect(response).to be_successful
    end
  end

  describe "Playlists" do
    it "GET /playlists" do
      create(:playlist)
      get admin_playlists_path
      expect(response).to be_successful
    end

    it "GET /playlists/:id" do
      playlist = create(:playlist)
      get admin_playlist_path(playlist)
      expect(response).to be_successful
    end
  end

  describe "QR Codes" do
    it "GET /qr_codes" do
      create(:qr_code)
      get admin_qr_codes_path
      expect(response).to be_successful
    end

    it "GET /qr_codes/:id" do
      qr = create(:qr_code)
      get admin_qr_code_path(qr)
      expect(response).to be_successful
    end
  end

  describe "QR Scans" do
    it "GET /qr_scans" do
      create(:qr_scan)
      get admin_qr_scans_path
      expect(response).to be_successful
    end

    it "GET /qr_scans/:id" do
      scan = create(:qr_scan)
      get admin_qr_scan_path(scan)
      expect(response).to be_successful
    end
  end
end
