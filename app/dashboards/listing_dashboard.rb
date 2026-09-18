require "administrate/base_dashboard"
require "administrate/field/active_storage"

class ListingDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    public_id: Field::String,
    account: Field::BelongsTo,
    address: Field::String,
    price: Field::String.with_options(searchable: false),
    beds: Field::Number,
    baths: Field::Number,
    sqft: Field::Number,
    status: Field::String,
    description: Field::Text,
    listing_type: Field::String,
    property_type: Field::String,
    listing_agents_count: Field::Number,
    photos: Field::ActiveStorage,
    agents: Field::HasMany,
    ads: Field::HasMany,
    qr_code: Field::HasOne,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id address price status account created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id public_id account address price beds baths sqft status description listing_type property_type listing_agents_count photos agents ads qr_code created_at ].freeze
  FORM_ATTRIBUTES = %i[ address price beds baths sqft status description listing_type property_type photos ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(listing)
    listing.address
  end
end
