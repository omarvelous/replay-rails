class AccountPolicy < ApplicationPolicy
  def update?  = owner?
  def edit?    = update?
  def destroy? = owner?
end
