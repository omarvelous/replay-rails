class QrCode < ApplicationRecord
  include PublicIdentifiable

  acts_as_tenant :account
  belongs_to :destination_record, polymorphic: true, optional: true

  validates :token, uniqueness: true
  validates :destination_url, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid HTTP(S) URL" }, allow_blank: true

  before_validation :generate_token, on: :create

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
