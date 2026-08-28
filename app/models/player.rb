class Player < ApplicationRecord
  has_paper_trail ignore: [ :last_heartbeat_at, :ip_address, :user_agent, :updated_at ]

  has_many :screen_players, dependent: :destroy
  has_one  :active_assignment, -> { active }, class_name: "ScreenPlayer"
  has_one  :screen, through: :active_assignment

  before_validation :generate_token, on: :create
  before_validation :generate_pairing_code, on: :create

  validates :token, uniqueness: true

  def paired?
    active_assignment.present?
  end

  def pairing_code_valid?
    pairing_code.present? && pairing_code_expires_at&.future?
  end

  def online?
    paired? && last_heartbeat_at.present? && last_heartbeat_at > 2.minutes.ago
  end

  def refresh_pairing_code!
    update!(
      pairing_code: SecureRandom.alphanumeric(6).upcase,
      pairing_code_expires_at: 10.minutes.from_now
    )
  end

  private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(32)
    end

    def generate_pairing_code
      self.pairing_code ||= SecureRandom.alphanumeric(6).upcase
      self.pairing_code_expires_at ||= 10.minutes.from_now
    end
end
