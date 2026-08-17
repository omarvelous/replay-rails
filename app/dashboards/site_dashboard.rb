require "administrate/base_dashboard"

class SiteDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    address: Field::String,
    account: Field::BelongsTo,
    screens: Field::HasMany,
    created_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id name address account screens ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id name address account screens created_at ].freeze
  FORM_ATTRIBUTES = %i[ name address ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(site)
    site.name
  end
end
