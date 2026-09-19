class Player < ApplicationRecord
  include PublicIdentifiable

  has_paper_trail ignore: [ :last_heartbeat_at, :ip_address, :user_agent, :pairing_code, :pairing_code_expires_at, :updated_at ]

  DEVICE_TYPES = %w[
    fire_tv android_tv raspberry_pi
    browser_desktop browser_mobile browser_tablet browser_tv
    provisioned unknown
  ].freeze

  has_many :player_sessions, dependent: :destroy
  has_many :screen_players, dependent: :destroy
  has_one  :active_assignment, -> { active }, class_name: "ScreenPlayer", inverse_of: :player
  has_one  :screen, through: :active_assignment

  validates :device_type, inclusion: { in: DEVICE_TYPES }, allow_nil: true

  before_validation :generate_pairing_code, on: :create

  def paired?
    active_assignment.present?
  end

  def pairing_code_valid?
    pairing_code.present? && pairing_code_expires_at&.future?
  end

  def online?
    paired? && last_heartbeat_at.present? && last_heartbeat_at > 2.minutes.ago
  end

  def provisioned?
    app_version.present?
  end

  def revoke_all_sessions!
    player_sessions.active.each(&:revoke!)
  end

  def refresh_pairing_code!
    update!(
      pairing_code: SecureRandom.alphanumeric(6).upcase,
      pairing_code_expires_at: 10.minutes.from_now
    )
  end

  private

    def generate_pairing_code
      self.pairing_code ||= SecureRandom.alphanumeric(6).upcase
      self.pairing_code_expires_at ||= 10.minutes.from_now
    end
end
