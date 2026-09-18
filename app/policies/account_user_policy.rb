class AccountUserPolicy < ApplicationPolicy
  def index? = account_user.at_least?("manager")
  def show?  = account_user.at_least?("manager")

  scope_for :active_record_relation do |relation|
    relation.where(account: account)
  end
end
