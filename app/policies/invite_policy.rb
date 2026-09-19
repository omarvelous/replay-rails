class InvitePolicy < ApplicationPolicy
  def index?   = manager_or_above?
  def create?  = owner? || (manager_or_above? && record.role == "agent")
  def new?     = create?
  def resend?  = manager_or_above?
  def destroy? = manager_or_above?
end
