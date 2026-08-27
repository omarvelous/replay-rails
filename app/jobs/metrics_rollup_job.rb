class MetricsRollupJob < ApplicationJob
  def perform(date = Date.yesterday)
    range = date.beginning_of_day..date.end_of_day
    now = Time.current

    bulk_insert("impressions", Impression.where(created_at: range).group(:account_id).count, range, now)
    bulk_insert("scans", QrScan.qualified.where(created_at: range).group(:account_id).count, range, now)
    bulk_insert("leads", Lead.where(created_at: range).group(:account_id).count, range, now)
  end

  private

  def bulk_insert(metric_name, grouped_counts, range, now)
    rows = grouped_counts.map do |account_id, value|
      { account_id: account_id, metric_name: metric_name,
        value: value, starts_at: range.first, ends_at: range.last,
        created_at: now, updated_at: now }
    end
    MetricSnapshot.insert_all(rows) if rows.any?
  end
end
