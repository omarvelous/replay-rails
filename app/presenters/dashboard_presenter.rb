class DashboardPresenter
  attr_reader :account

  def initialize(account:, period: 30.days)
    @account = account
    @period = period
  end

  def screens_online
    account.screens
      .joins(screen_players: :player)
      .where("players.last_heartbeat_at > ?", 2.minutes.ago)
      .distinct.count
  end

  def screens_total
    account.screens.count
  end

  def impressions_month
    account_events.where(name: "content.impressed").count
  end

  def scans_month
    account_events.where(name: "qr.scanned").count
  end

  def leads_month
    account.leads.where("created_at > ?", @period.ago).count
  end

  def leads_unread
    account.leads.unread.count
  end

  def recent_leads
    account.leads.order(created_at: :desc).limit(5)
  end

  def chart_impressions
    account_events.where(name: "content.impressed").group_by_day(:time).count
  end

  def chart_scans
    account_events.where(name: "qr.scanned").group_by_day(:time).count
  end

  def chart_leads
    account.leads.where("created_at > ?", @period.ago).group_by_day(:created_at).count
  end

  private

  def account_events
    Ahoy::Event.for_account(account).where("time > ?", @period.ago)
  end
end
