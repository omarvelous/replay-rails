module Analytics
  module Events
    class InteractionClosed < Base
      self.event_name = "interaction.closed"
      self.event_context = :kiosk

      attribute :experience_id, :integer
      attribute :screen_content_id, :integer
      attribute :target, :string
      attribute :view_duration, :integer

      validates :experience_id, :screen_content_id, :target,
                :view_duration, presence: true
    end
  end
end
