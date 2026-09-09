module Analytics
  module Events
    class InteractionEnded < Base
      self.event_name = "interaction.ended"
      self.event_context = :kiosk

      attribute :experience_id, :integer
      attribute :screen_id, :integer
      attribute :screen_content_id, :integer
      attribute :duration, :integer

      validates :experience_id, :screen_id, :screen_content_id,
                :duration, presence: true
    end
  end
end
