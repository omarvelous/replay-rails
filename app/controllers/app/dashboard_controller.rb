module App
  class DashboardController < App::BaseController
    def show
      @screens_online = Current.account.screens
                          .joins(screen_players: :player)
                          .where("players.last_heartbeat_at > ?", 2.minutes.ago)
                          .distinct.count
      @screens_total = Current.account.screens.count

      account_events = Ahoy::Event.where(account_id: Current.account.id).where("time > ?", 30.days.ago)

      @impressions_month = account_events.where(name: "content.impressed").count
      @scans_month = account_events.where(name: "redirect.followed").count
      @leads_month = Current.account.leads
                       .where("created_at > ?", 30.days.ago).count
      @leads_unread = Current.account.leads.unread.count

      @recent_leads = Current.account.leads.order(created_at: :desc).limit(5)

      @chart_impressions = account_events.where(name: "content.impressed")
                             .group_by_day(:time).count
      @chart_scans = account_events.where(name: "redirect.followed")
                       .group_by_day(:time).count
      @chart_leads = Current.account.leads
                       .where("created_at > ?", 30.days.ago).group_by_day(:created_at).count
    end
  end
end
