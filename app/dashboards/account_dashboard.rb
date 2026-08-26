require "administrate/base_dashboard"

class AccountDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    users: Field::HasMany,
    sites: Field::HasMany,
    listings: Field::HasMany,
    ads: Field::HasMany,
    playlists: Field::HasMany,
    qr_codes: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[ id users sites listings ads created_at ].freeze
  SHOW_PAGE_ATTRIBUTES = %i[ id users sites listings ads playlists qr_codes created_at updated_at ].freeze
  FORM_ATTRIBUTES = %i[].freeze
  COLLECTION_FILTERS = {}.freeze

  def display_resource(account)
    "Account ##{account.id}"
  end
end
