class Ahoy::VisitDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    visit_token: Field::String,
    visitor_token: Field::String,
    user: Field::BelongsTo,
    account_id: Field::Number,
    ip: Field::String,
    user_agent: Field::Text,
    referrer: Field::Text,
    referring_domain: Field::String,
    landing_page: Field::Text,
    browser: Field::String,
    os: Field::String,
    device_type: Field::String,
    utm_source: Field::String,
    utm_medium: Field::String,
    utm_campaign: Field::String,
    started_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[id visitor_token account_id browser device_type started_at].freeze
  SHOW_PAGE_ATTRIBUTES = %i[id visit_token visitor_token user account_id ip user_agent referrer referring_domain landing_page browser os device_type utm_source utm_medium utm_campaign started_at].freeze
  FORM_ATTRIBUTES = [].freeze
  COLLECTION_FILTERS = {}.freeze
end
