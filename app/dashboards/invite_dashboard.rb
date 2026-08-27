require "administrate/base_dashboard"

class InviteDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    invited_by: Field::BelongsTo.with_options(class_name: "User"),
    email: Field::String,
    role: Field::String,
    token: Field::String,
    accepted_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    email
    role
    accepted_at
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    invited_by
    email
    role
    token
    accepted_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    account
    email
    role
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
