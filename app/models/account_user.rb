class AccountUser < ApplicationRecord
  has_paper_trail

  ROLES = %w[owner manager agent].freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :role, uniqueness: { scope: [ :account_id, :user_id ] }
end
