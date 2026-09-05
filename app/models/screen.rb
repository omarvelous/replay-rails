class Screen < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]

  belongs_to :site
  has_many :screen_contents, dependent: :destroy
  has_many :screen_players, dependent: :destroy
  has_one  :active_player_assignment, -> { active }, class_name: "ScreenPlayer"
  has_one  :player, through: :active_player_assignment

  validates :name, presence: true
  validates :orientation, inclusion: { in: %w[landscape portrait] }

  scope :search, ->(q) { where("screens.name ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :live, -> { joins(:screen_contents).where(screen_contents: { active: true }).distinct }
  scope :idle, -> { where.not(id: live) }

  def active_screen_content
    screen_contents.find_by(active: true)
  end

  def active_content
    active_screen_content&.contentable
  end

  def content_type
    active_screen_content&.contentable_type&.downcase&.to_sym || :none
  end

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
