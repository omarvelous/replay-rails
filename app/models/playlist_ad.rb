class PlaylistAd < ApplicationRecord
  belongs_to :playlist
  belongs_to :ad

  validates :position, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
end
