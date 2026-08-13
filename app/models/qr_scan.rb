class QrScan < ApplicationRecord
  belongs_to :qr_code
  belongs_to :account
  belongs_to :source, polymorphic: true, optional: true
end
