module App
  class DashboardController < App::BaseController
    def show
      @screens_online = Current.account.screens
                          .joins(screen_players: :player)
                          .where("players.last_heartbeat_at > ?", 2.minutes.ago)
                          .distinct.count
      @screens_total = Current.account.screens.count

      @impressions_month = Impression.where(account: Current.account)
                             .where("created_at > ?", 30.days.ago).count
      @scans_month = QrScan.qualified.where(account: Current.account)
                       .where("created_at > ?", 30.days.ago).count
      @leads_month = Current.account.leads
                       .where("created_at > ?", 30.days.ago).count
      @leads_unread = Current.account.leads.unread.count

      @recent_leads = Current.account.leads.order(created_at: :desc).limit(5)

      @chart_impressions = Impression.where(account: Current.account)
                             .where("created_at > ?", 30.days.ago).group_by_day(:created_at).count
      @chart_scans = QrScan.qualified.where(account: Current.account)
                       .where("created_at > ?", 30.days.ago).group_by_day(:created_at).count
      @chart_leads = Current.account.leads
                       .where("created_at > ?", 30.days.ago).group_by_day(:created_at).count
    end
  end
end
