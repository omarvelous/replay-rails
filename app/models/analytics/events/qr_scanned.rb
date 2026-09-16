module Analytics
  module Events
    class QrScanned < Base
      self.event_name = "qr.scanned"
      self.event_context = :server

      attribute :qr_code_pid, :string
      attribute :destination_url, :string

      validates :qr_code_pid, :destination_url, presence: true

      QR_JOIN = "INNER JOIN qr_codes ON qr_codes.public_id::text = ahoy_events.properties->>'qr_code_pid'"

      module Scopes
        def for_creative(creative)
          joins(Analytics::Events::QrScanned::QR_JOIN)
            .where(qr_codes: { creative_type: creative.class.name, creative_id: creative.id })
        end

        def for_destination(destination)
          joins(Analytics::Events::QrScanned::QR_JOIN)
            .where(qr_codes: { destination_record_type: destination.class.name, destination_record_id: destination.id })
        end

        def contextual
          joins(Analytics::Events::QrScanned::QR_JOIN)
            .where.not(qr_codes: { creative_type: nil })
        end
      end
    end
  end
end
