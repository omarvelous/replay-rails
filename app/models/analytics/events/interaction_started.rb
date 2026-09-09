module Analytics
  module Events
    class InteractionStarted < Base
      self.event_name = "interaction.started"
      self.event_context = :kiosk

      attribute :experience_id, :integer
      attribute :screen_id, :integer
      attribute :screen_content_id, :integer

      validates :experience_id, :screen_id, :screen_content_id,
                presence: true
    end
  end
end
