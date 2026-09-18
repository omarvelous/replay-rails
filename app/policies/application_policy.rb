class ApplicationPolicy < ActionPolicy::Base
  # account_user is optional for unauthenticated invite acceptance.
  # Once InviteAcceptancesController is split out, this can become required.
  authorize :user, optional: true
  authorize :account, optional: true
  authorize :account_user, optional: true

  def index?   = true
  def show?    = true
  def create?  = manager_or_above?
  def new?     = create?
  def update?  = manager_or_above?
  def edit?    = update?
  def destroy? = manager_or_above?

  scope_for :active_record_relation do |relation|
    relation
  end

  private

  # Safe for unauthenticated contexts (invite acceptance).
  # Once InviteAcceptancesController is split out, the &. can be removed.
  def owner?
    account_user&.role == "owner"
  end

  def manager_or_above?
    account_user&.at_least?("manager") || false
  end

  def agent_or_above?
    account_user&.at_least?("agent") || false
  end
end
