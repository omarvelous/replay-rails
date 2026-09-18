class InvitePolicy < ApplicationPolicy
  # Read — inviter sees list, invitee sees their own invite
  def index? = manager_or_above?

  def show?
    user.nil? || user.email_address == record.email
  end

  # Write — role-based for inviters, identity-based for acceptance
  def create?
    return true if owner?
    manager_or_above? && record.role == "agent"
  end

  def new?     = create?

  def update?
    user.nil? || user.email_address == record.email
  end

  def resend?  = manager_or_above?
  def destroy? = manager_or_above?
end
