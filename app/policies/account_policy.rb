class AccountPolicy < ApplicationPolicy
  def edit?    = user&.owner_of?(account)
  def update?  = user&.owner_of?(account)
  def destroy? = user&.owner_of?(account)
end
