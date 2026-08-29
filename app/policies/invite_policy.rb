class InvitePolicy < ApplicationPolicy
  # Read — inviter sees list, invitee sees their own invite
  def index? = user&.can_manage?(account)

  def show?
    user.nil? || user.email_address == record.email
  end

  # Write — role-based for inviters, identity-based for acceptance
  def create?
    return true if user&.owner_of?(account)
    user&.can_manage?(account) && record.role == "agent"
  end

  def new?     = create?

  def update?
    user.nil? || user.email_address == record.email
  end

  def destroy? = user&.can_manage?(account)
end
