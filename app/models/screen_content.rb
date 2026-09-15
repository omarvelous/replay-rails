class ScreenContent < ApplicationRecord
  include PublicIdentifiable

  has_paper_trail

  belongs_to :screen
  delegated_type :contentable, types: %w[Playlist Experience]

  validates :active, uniqueness: { scope: :screen_id, conditions: -> { where(active: true) } },
            if: :active?

  after_commit :notify_player, on: %i[create update destroy]

  def self.find_contentable(type:, public_id:, account:)
    raise ActiveRecord::RecordNotFound unless type.in?(contentable_types)
    type.constantize.where(account: account).find_by_param!(public_id)
  end

  private

    def notify_player
      ActionCable.server.broadcast("screen_#{screen_id}", { event: "content_changed" })
    end
end
