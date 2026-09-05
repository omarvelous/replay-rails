class Experience < ApplicationRecord
  acts_as_tenant :account
  has_paper_trail

  belongs_to :listing
  belongs_to :agent, optional: true

  has_many :screen_contents, as: :contentable, dependent: :destroy
  has_many :screens, through: :screen_contents

  validates :listing, presence: true

  def default_agent
    agent || listing.listing_agents.first&.agent
  end
end
