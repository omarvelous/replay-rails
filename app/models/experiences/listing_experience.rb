module Experiences
  class ListingExperience < ApplicationRecord
    belongs_to :listing
    belongs_to :agent, optional: true

    has_one :experience, as: :experienceable, dependent: :destroy, touch: true

    validates :listing, presence: true

    def default_agent
      agent || listing.listing_agents.first&.agent
    end
  end
end
