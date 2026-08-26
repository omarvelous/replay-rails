class QrCode < ApplicationRecord
  belongs_to :account
  belongs_to :destination_record, polymorphic: true, optional: true

  has_many :scans, class_name: "QrScan", dependent: :destroy

  validates :token, uniqueness: true

  before_validation :generate_token, on: :create

  def destination?
    destination_url.present? || destination_record.present?
  end

  private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(8)
    end
end
