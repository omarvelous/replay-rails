require "administrate/base_dashboard"
require "administrate/field/active_storage"

class AdDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    adable: Field::Polymorphic,
    headline: Field::String,
    body: Field::Text,
    layout: Field::String,
    theme: Field::String,
    image: Field::ActiveStorage,
    playlists: Field::HasMany,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id headline adable layout theme account ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id account adable headline body layout theme image playlists created_at ].freeze
  FORM_ATTRIBUTES = %i[ headline body layout theme image ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(ad)
    ad.headline
  end
end
