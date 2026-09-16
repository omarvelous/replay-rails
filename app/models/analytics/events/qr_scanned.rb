module Analytics
  module Events
    class QrScanned < Base
      self.event_name = "qr.scanned"
      self.event_context = :server

      attribute :qr_code_pid, :string
      attribute :destination_url, :string

      validates :qr_code_pid, :destination_url, presence: true
    end
  end
end
