module Admin
  class DashboardController < ApplicationController
    def show
      # Infrastructure
      @total_accounts = Account.count
      @total_players = Player.count
      @players_online = Player.where("last_heartbeat_at > ?", 2.minutes.ago).count
      @total_screens = Screen.count

      # Funnel
      @total_impressions = Impression.count
      @impressions_today = Impression.where("created_at > ?", Date.current.beginning_of_day).count
      @total_scans = QrScan.qualified.count
      @scans_today = QrScan.qualified.where("created_at > ?", Date.current.beginning_of_day).count
      @total_leads = Lead.count
      @leads_this_week = Lead.where("created_at > ?", 7.days.ago).count
      @leads_unread = Lead.where(status: "new").count

      # Content
      @total_ads = Ad.count
      @total_listings = Listing.count
      @total_playlists = Playlist.count
      @total_qr_codes = QrCode.count
    end
  end
end
