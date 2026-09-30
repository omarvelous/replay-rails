class AccountPolicy < ApplicationPolicy
  def update?  = owner?
  def edit?    = update?
  def destroy? = owner?
  def switch?  = true

  scope_for :active_record_relation do |relation|
    relation.where(id: user.account_ids)
  end
end
