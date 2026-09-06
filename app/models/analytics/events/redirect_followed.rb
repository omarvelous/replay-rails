module Analytics
  module Events
    class RedirectFollowed < Base
      self.event_name = "redirect.followed"
      self.event_context = :server

      attribute :source, :string
      attribute :destination_url, :string
      attribute :status, :integer

      validates :source, :destination_url, :status, presence: true
    end
  end
end
