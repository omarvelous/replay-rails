module Analytics
  module Events
    class DeviceConnected < Base
      self.event_name = "device.connected"
      self.event_context = :player

      attribute :screen_id, :integer
      attribute :player_token, :string

      validates :screen_id, :player_token, presence: true
    end
  end
end
