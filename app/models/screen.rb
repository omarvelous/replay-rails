class Screen < ApplicationRecord
  belongs_to :site
  has_many :screen_playlists, dependent: :destroy
  has_many :playlists, through: :screen_playlists

  validates :name, presence: true
  validates :orientation, inclusion: { in: %w[landscape portrait] }

  scope :search, ->(q) { where("screens.name ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :live, -> { joins(:screen_playlists).where(screen_playlists: { active: true }).distinct }
  scope :idle, -> { where.not(id: live) }
end
