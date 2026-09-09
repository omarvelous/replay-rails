class Player < ApplicationRecord
  has_paper_trail ignore: [ :last_heartbeat_at, :ip_address, :user_agent, :pairing_code, :pairing_code_expires_at, :updated_at ]

  DEVICE_TYPES = %w[
    fire_tv android_tv raspberry_pi
    browser_desktop browser_mobile browser_tablet browser_tv
    provisioned unknown
  ].freeze

  has_many :screen_players, dependent: :destroy
  has_one  :active_assignment, -> { active }, class_name: "ScreenPlayer"
  has_one  :screen, through: :active_assignment

  validates :token, uniqueness: true
  validates :device_type, inclusion: { in: DEVICE_TYPES }, allow_nil: true

  before_validation :generate_token, on: :create
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

  def refresh_pairing_code!
    update!(
      pairing_code: SecureRandom.alphanumeric(6).upcase,
      pairing_code_expires_at: 10.minutes.from_now
    )
  end

  def parse_user_agent!
    return unless user_agent.present?

    client = DeviceDetector.new(user_agent)
    self.device_model = client.device_name.presence
    self.device_manufacturer = client.device_brand.presence
    self.os_name = client.os_name.presence
    self.os_version = client.os_full_version.presence
    self.browser_name = client.name.presence
    self.browser_version = client.full_version.presence
    self.device_type = infer_device_type(client)
    save!
  end

  private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(32)
    end

    def generate_pairing_code
      self.pairing_code ||= SecureRandom.alphanumeric(6).upcase
      self.pairing_code_expires_at ||= 10.minutes.from_now
    end

    def infer_device_type(client)
      return "fire_tv" if user_agent.include?("AFT")
      return "android_tv" if user_agent.include?("Android TV")
      return "raspberry_pi" if user_agent.include?("Raspbian") || user_agent.include?("raspberry")
      return "provisioned" if app_version.present?

      case client.device_type
      when "desktop" then "browser_desktop"
      when "smartphone" then "browser_mobile"
      when "tablet" then "browser_tablet"
      when "tv" then "browser_tv"
      else "unknown"
      end
    end
end
