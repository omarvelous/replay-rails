class BrandAd < ApplicationRecord
  LAYOUTS = %w[hero minimal].freeze

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  def default_headline = nil
end
