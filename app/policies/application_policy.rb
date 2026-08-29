class ApplicationPolicy < ActionPolicy::Base
  authorize :user, :account, optional: true

  def index?   = true
  def show?    = true
  def create?  = user&.can_manage?(account)
  def new?     = create?
  def update?  = user&.can_manage?(account)
  def edit?    = update?
  def destroy? = user&.can_manage?(account)

  scope_for :active_record_relation do |relation|
    relation
  end
end
