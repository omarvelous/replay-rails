require "rails_helper"

RSpec.describe "Admin Resources", type: :request do
  let(:admin) { create(:user, admin: true) }

  before do
    host! "admin.replay.localhost"
    sign_in(admin)
  end

  describe "Accounts" do
    it "GET /accounts returns a successful response" do
      create(:account)
      get admin_accounts_path
      expect(response).to be_successful
    end

    it "GET /accounts/:id returns a successful response" do
      account = create(:account)
      get admin_account_path(account)
      expect(response).to be_successful
    end
  end

  describe "Players" do
    it "GET /players returns a successful response" do
      create(:player)
      get admin_players_path
      expect(response).to be_successful
    end

    it "GET /players/:id returns a successful response" do
      player = create(:player)
      get admin_player_path(player)
      expect(response).to be_successful
    end
  end

  describe "Screens" do
    it "GET /screens returns a successful response" do
      create(:screen)
      get admin_screens_path
      expect(response).to be_successful
    end

    it "GET /screens/:id returns a successful response" do
      screen = create(:screen)
      get admin_screen_path(screen)
      expect(response).to be_successful
    end
  end

  describe "QR Codes" do
    it "GET /qr_codes returns a successful response" do
      create(:qr_code)
      get admin_qr_codes_path
      expect(response).to be_successful
    end

    it "GET /qr_codes/:id returns a successful response" do
      qr = create(:qr_code)
      get admin_qr_code_path(qr)
      expect(response).to be_successful
    end
  end

  describe "QR Scans" do
    it "GET /qr_scans returns a successful response" do
      create(:qr_scan)
      get admin_qr_scans_path
      expect(response).to be_successful
    end

    it "GET /qr_scans/:id returns a successful response" do
      scan = create(:qr_scan)
      get admin_qr_scan_path(scan)
      expect(response).to be_successful
    end
  end
end
