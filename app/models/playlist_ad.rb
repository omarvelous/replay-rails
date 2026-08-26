class PlaylistAd < ApplicationRecord
  belongs_to :playlist
  belongs_to :ad

  positioned on: :playlist

  validates :duration, presence: true, numericality: { greater_than: 0 }
  validate :same_account

  private

    def same_account
      return unless playlist && ad
      return if playlist.account_id == ad.account_id

      errors.add(:ad, "not found")
    end
end
