require "administrate/base_dashboard"

class QrCodeDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    public_id: Field::String,
    token: Field::String,
    account: Field::BelongsTo,
    destination_record_type: Field::String,
    destination_record_id: Field::Number,
    public_id: Field::String,
    destination_url: Field::String,
    label: Field::String,
    active: Field::Boolean,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id token account label active created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id public_id token account destination_record_type destination_record_id destination_url label active created_at ].freeze
  FORM_ATTRIBUTES = %i[ label active ].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(qr_code)
    qr_code.token
  end
end
