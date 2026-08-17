require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    first_name: Field::String,
    last_name: Field::String,
    email_address: Field::String,
    phone: Field::String,
    admin: Field::Boolean,
    account: Field::BelongsTo,
    sessions: Field::HasMany,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id first_name last_name email_address admin account ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id first_name last_name email_address phone admin account sessions created_at ].freeze
  FORM_ATTRIBUTES = %i[ first_name last_name email_address phone admin ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(user)
    "#{user.first_name} #{user.last_name}"
  end
end
