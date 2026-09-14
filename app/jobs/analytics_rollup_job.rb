class AnalyticsRollupJob < ApplicationJob
  queue_as :default

  def perform
    # Per-account rollups (grouped by account_id as a dimension)
    Analytics::Events::ContentImpressed.events.group(:account_id)
      .rollup("Impressions", interval: :day, column: :time)

    Analytics::Events::InteractionStarted.events.group(:account_id)
      .rollup("Kiosk Sessions", interval: :day, column: :time)

    Analytics::Events::QrScanned.events.group(:account_id)
      .rollup("QR Scans", interval: :day, column: :time)

    # Non-event rollups
    Lead.group(:account_id)
      .rollup("Leads", interval: :day)
  end
end
