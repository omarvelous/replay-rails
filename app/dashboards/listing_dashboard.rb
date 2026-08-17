require "administrate/base_dashboard"
require "administrate/field/active_storage"

class ListingDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    address: Field::String,
    price: Field::String.with_options(searchable: false),
    beds: Field::Number,
    baths: Field::Number,
    sqft: Field::Number,
    status: Field::String,
    photos: Field::ActiveStorage,
    agents: Field::HasMany,
    ads: Field::HasMany,
    qr_code: Field::HasOne,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id address price status account created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id account address price beds baths sqft status photos agents ads qr_code created_at ].freeze
  FORM_ATTRIBUTES = %i[ address price beds baths sqft status photos ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(listing)
    listing.address
  end
end
