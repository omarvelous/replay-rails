require "administrate/base_dashboard"

class LeadDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    listing: Field::BelongsTo,
    qr_scan: Field::BelongsTo,
    lead_agents: Field::HasMany,
    agents: Field::HasMany,
    lead_type: Field::String,
    status: Field::String,
    name: Field::String,
    email: Field::String,
    phone: Field::String,
    message: Field::Text,
    context: Field::String.with_options(searchable: false),
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    lead_type
    status
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    listing
    qr_scan
    lead_agents
    lead_type
    status
    name
    email
    phone
    message
    context
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    account
    lead_type
    status
    name
    email
    phone
    message
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
