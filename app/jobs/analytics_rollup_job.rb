class AnalyticsRollupJob < ApplicationJob
  queue_as :default

  def perform
    # Per-account rollups (grouped by account_pid from event properties)
    Analytics::Events::ContentImpressed.events
      .group("properties->>'account_pid'")
      .rollup("Impressions", interval: :day, column: :time)

    Analytics::Events::InteractionStarted.events
      .group("properties->>'account_pid'")
      .rollup("Kiosk Sessions", interval: :day, column: :time)

    Analytics::Events::QrScanned.events
      .group("properties->>'account_pid'")
      .rollup("QR Scans", interval: :day, column: :time)

    # Non-event rollups (Lead has account_id column — unchanged)
    Lead.group(:account_id)
      .rollup("Leads", interval: :day)
  end
end
