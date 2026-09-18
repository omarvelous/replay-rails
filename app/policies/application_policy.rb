class ApplicationPolicy < ActionPolicy::Base
  authorize :user, optional: true
  authorize :account, optional: true
  authorize :account_user, optional: true

  def index?   = true
  def show?    = true
  def create?  = account_user&.at_least?("manager") || false
  def new?     = create?
  def update?  = account_user&.at_least?("manager") || false
  def edit?    = update?
  def destroy? = account_user&.at_least?("manager") || false

  scope_for :active_record_relation do |relation|
    relation
  end
end
