class ApplicationPolicy < ActionPolicy::Base
  authorize :user, :account, :account_user

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

  def owner?
    account_user.role == "owner"
  end

  def manager_or_above?
    account_user.at_least?("manager")
  end

  def agent_or_above?
    account_user.at_least?("agent")
  end
end
