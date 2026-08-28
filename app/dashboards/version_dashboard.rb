require "administrate/base_dashboard"

class VersionDashboard < Administrate::BaseDashboard
  def self.model
    PaperTrail::Version
  end

  ATTRIBUTE_TYPES = {
    id: Field::Number,
    item_type: Field::String,
    item_id: Field::Number,
    event: Field::String,
    whodunnit: Field::String,
    object_changes: Field::String.with_options(searchable: false, truncate: 120),
    account_id: Field::Number,
    created_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    event
    item_type
    item_id
    whodunnit
    account_id
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    event
    item_type
    item_id
    whodunnit
    object_changes
    account_id
    created_at
  ].freeze

  FORM_ATTRIBUTES = [].freeze

  COLLECTION_FILTERS = {}.freeze
end
