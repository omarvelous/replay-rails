class QrScan < ApplicationRecord
  belongs_to :qr_code
  belongs_to :account
  belongs_to :ad, optional: true
  belongs_to :screen, optional: true

  store_accessor :context, :playlist_id, :slide_position

  scope :qualified, -> { where.not(ad_id: nil).where.not(screen_id: nil) }
  scope :unqualified, -> { where(ad_id: nil).or(where(screen_id: nil)) }
end
