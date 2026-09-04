class AccountUserPolicy < ApplicationPolicy
  def index? = user&.can_manage?(account)
  def show?  = user&.can_manage?(account)

  scope_for :active_record_relation do |relation|
    relation.where(account: account)
  end
end
