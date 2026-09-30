class AccountPolicy < ApplicationPolicy
  def update?  = owner?
  def edit?    = update?
  def destroy? = owner?
  def switch?  = true

  def self.accessible_by(user)
    if user.admin?
      Account.all
    else
      Account.where(id: user.account_ids)
    end
  end

  scope_for :active_record_relation do |relation|
    if user.admin?
      relation.all
    else
      relation.where(id: user.account_ids)
    end
  end
end
