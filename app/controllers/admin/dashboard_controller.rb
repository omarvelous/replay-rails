module Admin
  class DashboardController < BaseController
    def show
      @total_accounts = Account.count
      @total_players = Player.count
      @players_online = Player.where("last_heartbeat_at > ?", 2.minutes.ago).count
      @total_screens = Screen.count
      @total_qr_codes = QrCode.count
      @total_scans = QrScan.qualified.count
      @scans_today = QrScan.qualified.where("created_at > ?", Date.current.beginning_of_day).count
    end
  end
end
