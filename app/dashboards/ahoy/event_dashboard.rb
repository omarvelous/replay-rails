class Ahoy::EventDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    visit: Field::BelongsTo.with_options(class_name: "Ahoy::Visit"),
    user: Field::BelongsTo,
    account_id: Field::Number,
    name: Field::String,
    properties: Field::String.with_options(searchable: false),
    time: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id name account_id time].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id visit user account_id name properties time].freeze
  FORM_ATTRIBUTES = [].freeze
  COLLECTION_FILTERS = {}.freeze
end
