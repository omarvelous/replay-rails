require "administrate/base_dashboard"

class Ads::CollectionAdAdDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    ad: Field::BelongsTo,
    collection_ad: Field::BelongsTo,
    position: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    ad
    collection_ad
    position
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    ad
    collection_ad
    position
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    ad
    collection_ad
    position
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
