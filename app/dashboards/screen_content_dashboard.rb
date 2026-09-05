require "administrate/base_dashboard"

class ScreenContentDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    screen: Field::BelongsTo,
    contentable_type: Field::String,
    contentable_id: Field::Number,
    active: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id screen contentable_type contentable_id active].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id screen contentable_type contentable_id active created_at updated_at].freeze
  FORM_ATTRIBUTES = %i[screen contentable_type contentable_id active].freeze
  COLLECTION_FILTERS = {}.freeze
end
