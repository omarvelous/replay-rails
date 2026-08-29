class Playlist < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]
  acts_as_tenant :account
  has_many :playlist_ads, -> { order(:position) }, dependent: :destroy, inverse_of: :playlist
  has_many :ads, through: :playlist_ads
  has_many :screen_playlists, dependent: :destroy
  has_many :screens, through: :screen_playlists

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published archived] }

  scope :search, ->(q) { where("playlists.name ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :by_status, ->(s) { where(status: s) }
end
