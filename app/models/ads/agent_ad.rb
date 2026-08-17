module Ads
class AgentAd < ApplicationRecord
  LAYOUTS = %w[profile split].freeze

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  belongs_to :agent

  validates :agent, presence: true

  def default_headline = agent&.name
end
end
