require "administrate/base_dashboard"
require "administrate/field/active_storage"

class AgentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    name: Field::String,
    email: Field::String,
    phone: Field::String,
    photo: Field::ActiveStorage,
    user: Field::BelongsTo,
    listings: Field::HasMany,
    qr_code: Field::HasOne,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id name email phone account ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id account name email phone photo user listings qr_code created_at ].freeze
  FORM_ATTRIBUTES = %i[ name email phone photo ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(agent)
    agent.name
  end
end
