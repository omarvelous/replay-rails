class QrCode < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account
  belongs_to :destination_record, polymorphic: true, optional: true
  belongs_to :creative, polymorphic: true, optional: true
  belongs_to :screen_content, optional: true

  scope :contextual, -> { where.not(creative_type: nil) }
  scope :standalone, -> { where(creative_type: nil) }

  validates :token, uniqueness: true
  validates :destination_url, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid HTTP(S) URL" }, allow_blank: true

  before_validation :generate_token, on: :create

  def self.for(destination:, creative: nil, screen_content: nil)
    find_or_create_by!(
      destination_record: destination,
      creative: creative,
      screen_content: screen_content
    ) do |qr|
      qr.account = destination.account
      qr.label = (destination.try(:address) || destination.try(:name))&.truncate(40)
    end
  end

  def destination?
    destination_url.present? || destination_record.present?
  end

  def scan_events
    Analytics::Events::QrScanned.where_properties(qr_code_id: id)
  end

  def scan_count
    scan_events.count
  end

  private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(8)
    end
end
