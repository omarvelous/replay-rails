class Screen < ApplicationRecord
  belongs_to :site
  has_many :screen_playlists, dependent: :destroy
  has_many :playlists, through: :screen_playlists

  validates :name, presence: true
  validates :orientation, inclusion: { in: %w[landscape portrait] }
end
