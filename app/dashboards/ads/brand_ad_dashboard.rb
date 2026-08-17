require "administrate/base_dashboard"

class Ads::BrandAdDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    ad: Field::HasOne,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    ad
    created_at
    updated_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    ad
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    ad
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
