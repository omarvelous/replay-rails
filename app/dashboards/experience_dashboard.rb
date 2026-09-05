require "administrate/base_dashboard"

class ExperienceDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    experienceable_type: Field::String,
    experienceable_id: Field::Number,
    name: Field::String,
    config: Field::String.with_options(searchable: false),
    screen_contents: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id account name experienceable_type created_at].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id account name experienceable_type experienceable_id config screen_contents created_at updated_at].freeze
  FORM_ATTRIBUTES = %i[name config].freeze
  COLLECTION_FILTERS = {}.freeze
end
