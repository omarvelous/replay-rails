class UserPolicy < ApplicationPolicy
  def index? = account_user.at_least?("manager")
  def show?  = account_user.at_least?("manager")

  scope_for :active_record_relation do |relation|
    relation.joins(:account_users)
            .where(account_users: { account_id: account.id })
            .distinct
  end
end
