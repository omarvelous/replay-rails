class ApplicationPolicy
  attr_reader :account_user, :record

  def initialize(account_user, record)
    @account_user = account_user
    @record = record
  end

  def index?   = true
  def show?    = true
  def create?  = account_user.can_manage?
  def new?     = create?
  def update?  = account_user.can_manage?
  def edit?    = update?
  def destroy? = account_user.can_manage?

  class Scope
    def initialize(account_user, scope)
      @account_user = account_user
      @scope = scope
    end

    def resolve = scope.all

    private

    attr_reader :account_user, :scope
  end
end
