require "administrate/base_dashboard"

class Ads::ListingAdDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    ad: Field::HasOne,
    badge: Field::String,
    event_date: Field::Date,
    event_end_time: Field::Time,
    event_start_time: Field::Time,
    listing: Field::BelongsTo,
    original_price: Field::Number,
    sold_date: Field::Date,
    sold_price: Field::Number,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    ad
    badge
    event_date
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    ad
    badge
    event_date
    event_end_time
    event_start_time
    listing
    original_price
    sold_date
    sold_price
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    ad
    badge
    event_date
    event_end_time
    event_start_time
    listing
    original_price
    sold_date
    sold_price
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
