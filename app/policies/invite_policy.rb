class InvitePolicy < ApplicationPolicy
  # Read — inviter sees list, invitee sees their own invite
  def index? = account_user.at_least?("manager")

  def show?
    user.nil? || user.email_address == record.email
  end

  # Write — role-based for inviters, identity-based for acceptance
  def create?
    return true if account_user.role == "owner"
    account_user.at_least?("manager") && record.role == "agent"
  end

  def new?     = create?

  def update?
    user.nil? || user.email_address == record.email
  end

  def resend?  = account_user.at_least?("manager")
  def destroy? = account_user.at_least?("manager")
end
