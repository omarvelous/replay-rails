module Analytics
  module Events
    class ContentLoaded < Base
      self.event_name = "content.loaded"
      self.event_context = :player

      attribute :screen_id, :integer
      attribute :screen_content_id, :integer
      attribute :content_type, :string
      attribute :content_id, :integer

      validates :screen_id, :screen_content_id,
                :content_type, :content_id,
                presence: true
    end
  end
end
