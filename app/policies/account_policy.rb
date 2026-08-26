class AccountPolicy < ApplicationPolicy
  def edit?    = account_user.owner?
  def update?  = account_user.owner?
  def destroy? = account_user.owner?
end
