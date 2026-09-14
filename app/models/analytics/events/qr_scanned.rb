module Analytics
  module Events
    class QrScanned < Base
      self.event_name = "qr.scanned"
      self.event_context = :server

      attribute :qr_code_pid,        :string
      attribute :destination_url,    :string
      attribute :screen_content_pid, :string
      attribute :ad_pid,             :string
      attribute :screen_pid,         :string

      validates :qr_code_pid, :destination_url, presence: true

      module Scopes
        def qualified
          where("properties ? 'ad_pid' AND properties ? 'screen_pid'")
        end
      end
    end
  end
end
