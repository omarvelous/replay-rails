class ScreenPlaylist < ApplicationRecord
  has_paper_trail
  belongs_to :screen
  belongs_to :playlist

  after_commit :notify_player, on: %i[ create update destroy ]

  private

    def notify_player
      ActionCable.server.broadcast("screen_#{screen_id}", { event: "playlist_changed" })
    end
end
