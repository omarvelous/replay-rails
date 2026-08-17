require "administrate/base_dashboard"

class Ads::CollectionAdDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    ad: Field::HasOne,
    collection_ad_ads: Field::HasMany,
    collection_title: Field::String,
    member_ads: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    ad
    collection_ad_ads
    collection_title
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    ad
    collection_ad_ads
    collection_title
    member_ads
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    ad
    collection_ad_ads
    collection_title
    member_ads
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
