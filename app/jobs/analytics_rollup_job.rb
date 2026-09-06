class AnalyticsRollupJob < ApplicationJob
  queue_as :default

  def perform
    # Per-account rollups (grouped by account_id as a dimension)
    Ahoy::Event.where(name: "content.impressed").group(:account_id)
      .rollup("Impressions", interval: :day, column: :time)

    Ahoy::Event.where(name: "interaction.started").group(:account_id)
      .rollup("Kiosk Sessions", interval: :day, column: :time)

    Ahoy::Event.where(name: "qr.scanned").group(:account_id)
      .rollup("QR Scans", interval: :day, column: :time)
  end
end
