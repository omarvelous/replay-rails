module Analytics
  module Events
    class DeviceConnected < Base
      self.event_name = "device.connected"
      self.event_context = :player

      attribute :screen_pid,  :string
      attribute :player_pid, :string

      validates :screen_pid, :player_pid, presence: true
    end
  end
end
