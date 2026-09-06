module Analytics
  module Events
    class QrScanned < Base
      self.event_name = "qr.scanned"
      self.event_context = :server

      attribute :qr_code_id, :integer
      attribute :destination_url, :string
      attribute :screen_content_id, :integer
      attribute :ad_id, :integer
      attribute :screen_id, :integer

      validates :qr_code_id, :destination_url, presence: true
    end
  end
end
