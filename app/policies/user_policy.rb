class UserPolicy < ApplicationPolicy
  def index? = manager_or_above?
  def show?  = manager_or_above?

  scope_for :active_record_relation do |relation|
    relation.joins(:account_users)
            .where(account_users: { account_id: account.id })
            .distinct
  end
end
