class ApplicationPolicy < ActionPolicy::Base
  authorize :user, :account, :account_user

  def index?   = true
  def show?    = true
  def create?  = account_user.at_least?("manager")
  def new?     = create?
  def update?  = account_user.at_least?("manager")
  def edit?    = update?
  def destroy? = account_user.at_least?("manager")

  scope_for :active_record_relation do |relation|
    relation
  end
end
