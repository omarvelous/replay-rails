class DashboardPresenter
  attr_reader :account

  def initialize(account:, period: 30.days)
    @account = account
    @period = period
  end

  def screens_online
    cached("screens_online") do
      account.screens
        .joins(screen_players: :player)
        .where("players.last_heartbeat_at > ?", 2.minutes.ago)
        .distinct.count
    end
  end

  def screens_total
    cached("screens_total") { account.screens.count }
  end

  def impressions_month
    cached("impressions_month") { account_events.where(name: "content.impressed").count }
  end

  def scans_month
    cached("scans_month") { account_events.where(name: "qr.scanned").count }
  end

  def leads_month
    cached("leads_month") { account.leads.where("created_at > ?", @period.ago).count }
  end

  def leads_unread
    account.leads.unread.count
  end

  def recent_leads
    account.leads.order(created_at: :desc).limit(5)
  end

  def chart_impressions
    cached("chart_impressions") { account_events.where(name: "content.impressed").group_by_day(:time).count }
  end

  def chart_scans
    cached("chart_scans") { account_events.where(name: "qr.scanned").group_by_day(:time).count }
  end

  def chart_leads
    cached("chart_leads") { account.leads.where("created_at > ?", @period.ago).group_by_day(:created_at).count }
  end

  private

  def cached(key, expires_in: 5.minutes, &block)
    Rails.cache.fetch("dashboard/#{account.id}/#{key}", expires_in: expires_in, &block)
  end

  def account_events
    Ahoy::Event.for_account(account).where("time > ?", @period.ago)
  end
end
