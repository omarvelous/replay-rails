module Admin
  class DashboardController < Admin::ApplicationController
    def show
      # Infrastructure
      @total_accounts = Account.count
      @total_players = Player.count
      @players_online = Player.where("last_heartbeat_at > ?", 2.minutes.ago).count
      @total_screens = Screen.count

      # Funnel
      @total_impressions = Analytics::Events::ContentImpressed.events.count
      @impressions_today = Analytics::Events::ContentImpressed.events
                             .where("time > ?", Date.current.beginning_of_day).count
      qualified_scans = Analytics::Events::QrScanned.events.qualified
      @total_scans = qualified_scans.count
      @scans_today = qualified_scans.where("time > ?", Date.current.beginning_of_day).count
      @total_leads = Lead.count
      @leads_this_week = Lead.where("created_at > ?", 7.days.ago).count
      @leads_unread = Lead.where(status: "new").count

      # Content
      @total_ads = Ad.count
      @total_listings = Listing.count
      @total_playlists = Playlist.count
      @total_qr_codes = QrCode.count

      # Recent activity
      @recent_versions = ::PaperTrail::Version.order(created_at: :desc).limit(15)
    end
  end
end
