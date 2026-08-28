class VersionCleanupJob < ApplicationJob
  def perform(retention_days: 90)
    PaperTrail::Version
      .where("created_at < ?", retention_days.days.ago)
      .in_batches
      .delete_all
  end
end
