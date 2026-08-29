class QrCode < ApplicationRecord
  acts_as_tenant :account
  belongs_to :destination_record, polymorphic: true, optional: true

  has_many :scans, class_name: "QrScan", dependent: :destroy

  validates :token, uniqueness: true
  validates :destination_url, format: { with: /\Ahttps?:\/\/\S+\z/i, message: "must be a valid HTTP(S) URL" }, allow_blank: true

  before_validation :generate_token, on: :create

  def destination?
    destination_url.present? || destination_record.present?
  end

  private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(8)
    end
end
