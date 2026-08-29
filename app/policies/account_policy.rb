class AccountPolicy < ApplicationPolicy
  def update?  = user&.owner_of?(account)
  def edit?    = update?
  def destroy? = user&.owner_of?(account)
end
