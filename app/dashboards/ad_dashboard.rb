require "administrate/base_dashboard"

class AdDashboard < Administrate::BaseDashboard
  # ATTRIBUTE_TYPES
  # a hash that describes the type of each of the model's fields.
  #
  # Each different type represents an Administrate::Field object,
  # which determines how the attribute is displayed
  # on pages throughout the dashboard.
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    adable: Field::Polymorphic,
    body: Field::Text,
    collection_ad_ads: Field::HasMany,
    headline: Field::String,
    image_attachment: Field::HasOne,
    image_blob: Field::HasOne,
    layout: Field::String,
    playlist_ads: Field::HasMany,
    playlists: Field::HasMany,
    theme: Field::String,
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
    account
    adable
    body
  ].freeze

  # SHOW_PAGE_ATTRIBUTES
  # an array of attributes that will be displayed on the model's show page.
  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    adable
    body
    collection_ad_ads
    headline
    image_attachment
    image_blob
    layout
    playlist_ads
    playlists
    theme
    created_at
    updated_at
  ].freeze

  # FORM_ATTRIBUTES
  # an array of attributes that will be displayed
  # on the model's form (`new` and `edit`) pages.
  FORM_ATTRIBUTES = %i[
    account
    adable
    body
    collection_ad_ads
    headline
    image_attachment
    image_blob
    layout
    playlist_ads
    playlists
    theme
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

  # Overwrite this method to customize how ads are displayed
  # across all pages of the admin dashboard.
  #
  # def display_resource(ad)
  #   "Ad ##{ad.id}"
  # end
end
