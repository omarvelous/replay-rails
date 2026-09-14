module Ads
class CollectionAdAd < ApplicationRecord
  include PublicIdentifiable

  belongs_to :collection_ad
  belongs_to :ad
end
end
