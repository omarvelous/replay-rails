require "administrate/base_dashboard"

class AccountUserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    user: Field::BelongsTo,
    role: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id account user role created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id account user role created_at updated_at ].freeze
  FORM_ATTRIBUTES = %i[ account user role ].freeze
  COLLECTION_FILTERS = {}.freeze
end
