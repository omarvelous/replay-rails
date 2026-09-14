module Analytics
  module Events
    class InteractionClosed < Base
      self.event_name = "interaction.closed"
      self.event_context = :kiosk

      attribute :experience_pid,     :string
      attribute :screen_content_pid, :string
      attribute :target,             :string
      attribute :view_duration,      :integer

      validates :experience_pid, :screen_content_pid, :target,
                :view_duration, presence: true
    end
  end
end
