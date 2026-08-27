class UserPolicy < ApplicationPolicy
  def index? = user&.can_manage?(account)
  def show?  = user&.can_manage?(account)

  scope_for :active_record_relation do |relation|
    relation.joins(:account_users)
            .where(account_users: { account_id: account.id })
            .distinct
  end
end
