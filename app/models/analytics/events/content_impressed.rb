module Analytics
  module Events
    class ContentImpressed < Base
      self.event_name = "content.impressed"
      self.event_context = :player

      attribute :ad_id, :integer
      attribute :screen_id, :integer
      attribute :screen_content_id, :integer
      attribute :playlist_id, :integer
      attribute :position, :integer
      attribute :duration, :integer

      validates :ad_id, :screen_id, :screen_content_id,
                :playlist_id, :position, :duration,
                presence: true
    end
  end
end
