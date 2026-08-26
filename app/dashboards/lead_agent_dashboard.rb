require "administrate/base_dashboard"

class LeadAgentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    lead: Field::BelongsTo,
    agent: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    lead
    agent
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    lead
    agent
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    lead
    agent
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
