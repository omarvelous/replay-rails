module Analytics
  module Events
    class InteractionOpened < Base
      self.event_name = "interaction.opened"
      self.event_context = :kiosk

      attribute :experience_id, :integer
      attribute :screen_content_id, :integer
      attribute :target, :string

      validates :experience_id, :screen_content_id, :target,
                presence: true
    end
  end
end
