module Analytics
  module Events
    class InteractionOpened < Base
      self.event_name = "interaction.opened"
      self.event_context = :kiosk

      attribute :experience_pid,     :string
      attribute :screen_content_pid, :string
      attribute :target,             :string

      validates :experience_pid, :screen_content_pid, :target,
                presence: true
    end
  end
end
