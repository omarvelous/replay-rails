class PlayerCleanupJob < ApplicationJob
  def perform(retention_hours: 24)
    Player
      .where("created_at < ?", retention_hours.hours.ago)
      .where.not(id: ScreenPlayer.select(:player_id))
      .in_batches
      .delete_all
  end
end
