module Analytics
  module Events
    class ContentLoaded < Base
      self.event_name = "content.loaded"
      self.event_context = :player

      attribute :screen_pid,         :string
      attribute :screen_content_pid, :string
      attribute :content_type,       :string
      attribute :content_pid,        :string

      validates :screen_pid, :screen_content_pid,
                :content_type, :content_pid,
                presence: true
    end
  end
end
