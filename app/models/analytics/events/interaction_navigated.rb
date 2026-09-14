module Analytics
  module Events
    class InteractionNavigated < Base
      self.event_name = "interaction.navigated"
      self.event_context = :kiosk

      attribute :experience_pid,     :string
      attribute :screen_content_pid, :string
      attribute :direction,          :string
      attribute :photo_index,        :integer

      validates :experience_pid, :screen_content_pid,
                :direction, :photo_index,
                presence: true
    end
  end
end
