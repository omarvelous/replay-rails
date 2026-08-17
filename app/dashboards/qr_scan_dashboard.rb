require "administrate/base_dashboard"

class QrScanDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    qr_code: Field::BelongsTo,
    account: Field::BelongsTo,
    ad: Field::BelongsTo,
    screen: Field::BelongsTo,
    ip_address: Field::String,
    user_agent: Field::String,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id qr_code account ad screen created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id qr_code account ad screen ip_address user_agent created_at ].freeze
  FORM_ATTRIBUTES = %i[].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(scan)
    "Scan ##{scan.id}"
  end
end
