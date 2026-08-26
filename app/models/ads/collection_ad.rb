module Ads
class CollectionAd < ApplicationRecord
  LAYOUTS = %w[grid].freeze
  MAX_ITEMS = 8

  has_one :ad, as: :adable, dependent: :destroy, touch: true

  has_many :collection_ad_ads, dependent: :destroy
  has_many :member_ads, through: :collection_ad_ads, source: :ad

  validates :collection_title, presence: true

  def default_headline = collection_title
end
end
