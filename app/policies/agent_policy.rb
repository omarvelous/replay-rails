class AgentPolicy < ApplicationPolicy
  def update? = account_user.can_manage? || own_profile?
  def edit?   = update?

  private

  def own_profile?
    record.user_id == account_user.user_id
  end
end
