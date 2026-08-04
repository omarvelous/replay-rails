class Ad < ApplicationRecord
  belongs_to :account
  belongs_to :listing, optional: true
  has_many :playlist_ads, dependent: :destroy
  has_many :playlists, through: :playlist_ads

  validates :headline, presence: true
end
