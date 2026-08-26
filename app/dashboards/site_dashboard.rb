require "administrate/base_dashboard"
require "administrate/field/active_storage"

class SiteDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    address: Field::String,
    photo: Field::ActiveStorage,
    account: Field::BelongsTo,
    screens: Field::HasMany,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id name address account screens ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id name address photo account screens created_at ].freeze
  FORM_ATTRIBUTES = %i[ name address photo ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(site)
    site.name
  end
end
