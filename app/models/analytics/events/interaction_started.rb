module Analytics
  module Events
    class InteractionStarted < Base
      self.event_name = "interaction.started"
      self.event_context = :kiosk

      attribute :experience_pid,     :string
      attribute :screen_pid,         :string
      attribute :screen_content_pid, :string

      validates :experience_pid, :screen_pid, :screen_content_pid,
                presence: true
    end
  end
end
