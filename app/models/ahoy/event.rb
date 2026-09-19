class Ahoy::Event < ApplicationRecord
  include Ahoy::QueryMethods

  self.table_name = "ahoy_events"

  belongs_to :visit
  belongs_to :user, optional: true

  scope :for_account, ->(account) { where_properties(account_pid: account.public_id) }
end
