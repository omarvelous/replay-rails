require "administrate/base_dashboard"

class PlayerDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    token: Field::String,
    pairing_code: Field::String,
    last_heartbeat_at: Field::DateTime,
    ip_address: Field::String,
    user_agent: Field::String,
    firmware_version: Field::String,
    screen_players: Field::HasMany,
    created_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id ip_address last_heartbeat_at firmware_version created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id token pairing_code last_heartbeat_at ip_address user_agent firmware_version screen_players created_at ].freeze
  FORM_ATTRIBUTES = %i[ firmware_version ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(player)
    "Player ##{player.id}"
  end
end
