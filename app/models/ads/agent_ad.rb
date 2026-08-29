module Ads
class AgentAd < ApplicationRecord
  LAYOUTS = %w[profile split].freeze

  belongs_to :agent
  has_one :ad, as: :adable, dependent: :destroy, touch: true

  validates :agent, presence: true

  def default_headline = agent&.name
end
end
