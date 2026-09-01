class Screen < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]

  belongs_to :site
  has_many :screen_playlists, dependent: :destroy
  has_many :playlists, through: :screen_playlists
  has_many :screen_players, dependent: :destroy
  has_one  :active_player_assignment, -> { active }, class_name: "ScreenPlayer"
  has_one  :player, through: :active_player_assignment

  validates :name, presence: true
  validates :orientation, inclusion: { in: %w[landscape portrait] }

  scope :search, ->(q) { where("screens.name ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :live, -> { joins(:screen_playlists).where(screen_playlists: { active: true }).distinct }
  scope :idle, -> { where.not(id: live) }

  def paired?
    player.present?
  end

  def online?
    player&.online?
  end

  def pair_player!(player, paired_by: nil)
    with_lock do
      reload_active_player_assignment&.unpair!
      player.reload_active_assignment&.unpair!

      screen_players.create!(
        player: player,
        paired_by: paired_by
      )

      player.update!(pairing_code: nil, pairing_code_expires_at: nil)
    end
  end

  def unpair_player!
    reload_active_player_assignment&.unpair!
  end
end
