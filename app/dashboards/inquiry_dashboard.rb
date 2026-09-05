require "administrate/base_dashboard"

class InquiryDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    email: Field::String,
    phone: Field::String,
    company: Field::String,
    inquiry_type: Field::String,
    interest: Field::String,
    message: Field::Text,
    responded_at: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    name
    email
    company
    inquiry_type
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    email
    phone
    company
    inquiry_type
    interest
    message
    responded_at
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    email
    phone
    company
    inquiry_type
    interest
    message
    responded_at
  ].freeze

  COLLECTION_FILTERS = {}.freeze
end
