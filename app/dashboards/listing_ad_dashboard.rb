require "administrate/base_dashboard"

class ListingAdDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
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

  # COLLECTION_ATTRIBUTES
  # an array of attributes that will be displayed on the model's index page.
  #
  # By default, it's limited to four items to reduce clutter on index pages.
  # Feel free to add, remove, or rearrange items.
  COLLECTION_ATTRIBUTES = %i[
    id
    ad
    badge
    event_date
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
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

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
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

  # COLLECTION_FILTERS
  # a hash that defines filters that can be used while searching via the search
  # field of the dashboard.
  #
  # For example to add an option to search for open resources by typing "open:"
  # in the search field:
  #
  #   COLLECTION_FILTERS = {
  #     open: ->(resources) { resources.where(open: true) }
  #   }.freeze
  COLLECTION_FILTERS = {}.freeze

  # Overwrite this method to customize how listing ads are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(listing_ad)
  #   "ListingAd ##{listing_ad.id}"
  # end
end
