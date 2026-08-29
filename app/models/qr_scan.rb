class QrScan < ApplicationRecord
  acts_as_tenant :account

  store_accessor :context, :playlist_id, :slide_position

  belongs_to :qr_code
  belongs_to :ad, optional: true
  belongs_to :screen, optional: true
  has_many :leads

  scope :qualified, -> { where.not(ad_id: nil).where.not(screen_id: nil) }
  scope :unqualified, -> { where(ad_id: nil).or(where(screen_id: nil)) }
end
