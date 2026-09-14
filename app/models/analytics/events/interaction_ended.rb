module Analytics
  module Events
    class InteractionEnded < Base
      self.event_name = "interaction.ended"
      self.event_context = :kiosk

      attribute :experience_pid,     :string
      attribute :screen_pid,         :string
      attribute :screen_content_pid, :string
      attribute :duration,           :integer

      validates :experience_pid, :screen_pid, :screen_content_pid,
                :duration, presence: true
    end
  end
end
