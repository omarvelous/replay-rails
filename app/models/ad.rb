class Ad < ApplicationRecord
  belongs_to :account
  belongs_to :listing, optional: true
  has_many :playlist_ads, dependent: :destroy
  has_many :playlists, through: :playlist_ads

  validates :headline, presence: true

  scope :search, ->(q) { where("ads.headline ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :listing_ads, -> { where.not(listing_id: nil) }
  scope :standalone, -> { where(listing_id: nil) }
end
