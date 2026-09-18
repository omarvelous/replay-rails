class AccountUser < ApplicationRecord
  include PublicIdentifiable

  has_paper_trail

  ROLES = %w[owner manager agent].freeze
  ROLE_HIERARCHY = { "owner" => 0, "manager" => 1, "agent" => 2 }.freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }

  before_destroy :ensure_not_last_owner

  def at_least?(required_role)
    ROLE_HIERARCHY[role] <= ROLE_HIERARCHY[required_role]
  end

  private

    def ensure_not_last_owner
      return unless role == "owner"

      if account.account_users.where(role: "owner").count <= 1
        errors.add(:base, "Cannot remove the last owner")
        throw(:abort)
      end
    end
end
