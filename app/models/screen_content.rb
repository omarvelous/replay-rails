class ScreenContent < ApplicationRecord
  has_paper_trail

  belongs_to :screen
  delegated_type :contentable, types: %w[Playlist Experience]

  validates :active, uniqueness: { scope: :screen_id, conditions: -> { where(active: true) } },
            if: :active?

  after_commit :notify_player, on: %i[create update destroy]

  private

    def notify_player
      ActionCable.server.broadcast("screen_#{screen_id}", { event: "content_changed" })
    end
end
