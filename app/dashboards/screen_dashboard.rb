require "administrate/base_dashboard"

class ScreenDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    orientation: Field::String,
    site: Field::BelongsTo,
    screen_playlists: Field::HasMany,
    screen_players: Field::HasMany,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id name orientation site created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id name orientation site screen_playlists screen_players created_at ].freeze
  FORM_ATTRIBUTES = %i[ name orientation ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(screen)
    screen.name
  end
end
