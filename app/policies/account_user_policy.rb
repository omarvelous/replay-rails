class AccountUserPolicy < ApplicationPolicy
  def index? = manager_or_above?
  def show?  = manager_or_above?

  scope_for :active_record_relation do |relation|
    relation.where(account: account)
  end
end
