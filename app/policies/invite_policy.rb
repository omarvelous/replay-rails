class InvitePolicy < ApplicationPolicy
  # Inviter actions — role-based
  def index?   = user&.can_manage?(account)
  def new?     = user&.can_manage?(account)
  def destroy? = user&.can_manage?(account)

  def create?
    return true if user&.owner_of?(account)
    user&.can_manage?(account) && record.role == "agent"
  end

  # Invitee actions — identity-based
  def show?
    user.nil? || user.email_address == record.email
  end

  def update?
    user.nil? || user.email_address == record.email
  end

end
