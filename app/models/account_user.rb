class AccountUser < ApplicationRecord
  has_paper_trail

  ROLES = %w[owner manager agent].freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :role, uniqueness: { scope: [ :account_id, :user_id ] }

  before_destroy :ensure_not_last_owner

  private

    def ensure_not_last_owner
      return unless role == "owner"

      if account.account_users.where(role: "owner").count <= 1
        errors.add(:base, "Cannot remove the last owner")
        throw(:abort)
      end
    end
end
