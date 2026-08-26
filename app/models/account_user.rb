class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  ROLES = %w[owner manager agent].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }

  def owner?      = role == "owner"
  def manager?    = role == "manager"
  def agent_role? = role == "agent"

  def can_manage?
    owner? || manager?
  end
end
