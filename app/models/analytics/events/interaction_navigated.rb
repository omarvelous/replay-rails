module Analytics
  module Events
    class InteractionNavigated < Base
      self.event_name = "interaction.navigated"
      self.event_context = :kiosk

      attribute :experience_id, :integer
      attribute :screen_content_id, :integer
      attribute :direction, :string
      attribute :photo_index, :integer

      validates :experience_id, :screen_content_id,
                :direction, :photo_index,
                presence: true
    end
  end
end
