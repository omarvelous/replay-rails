class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  ROLES = %w[owner manager agent].freeze

  validates :role, inclusion: { in: ROLES }
  validates :role, uniqueness: { scope: [ :account_id, :user_id ] }
end
