class AccountPolicy < ApplicationPolicy
  def update?  = account_user.role == "owner"
  def edit?    = update?
  def destroy? = account_user.role == "owner"
end
