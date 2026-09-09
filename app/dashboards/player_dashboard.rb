require "administrate/base_dashboard"

class PlayerDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    token: Field::String,
    device_name: Field::String,
    device_type: Field::String,
    device_model: Field::String,
    device_manufacturer: Field::String,
    os_name: Field::String,
    os_version: Field::String,
    browser_name: Field::String,
    browser_version: Field::String,
    app_version: Field::String,
    screen_width: Field::Number,
    screen_height: Field::Number,
    touch_capable: Field::Boolean,
    pairing_code: Field::String,
    last_heartbeat_at: Field::DateTime,
    ip_address: Field::String,
    user_agent: Field::Text,
    screen_players: Field::HasMany,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id device_name device_type device_model ip_address last_heartbeat_at].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id token device_name device_type device_model device_manufacturer os_name os_version browser_name browser_version app_version screen_width screen_height touch_capable pairing_code last_heartbeat_at ip_address user_agent screen_players created_at].freeze
  FORM_ATTRIBUTES = %i[device_name].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(player)
    player.device_name.presence || "Player ##{player.id}"
  end
end
