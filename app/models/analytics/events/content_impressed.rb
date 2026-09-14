module Analytics
  module Events
    class ContentImpressed < Base
      self.event_name = "content.impressed"
      self.event_context = :player

      attribute :ad_pid,             :string
      attribute :screen_pid,         :string
      attribute :screen_content_pid, :string
      attribute :playlist_pid,       :string
      attribute :position,           :integer
      attribute :duration,           :integer

      validates :ad_pid, :screen_pid, :screen_content_pid,
                :playlist_pid, :position, :duration,
                presence: true
    end
  end
end
