class AgentPolicy < ApplicationPolicy
  def update? = user.can_manage?(account) || own_profile?
  def edit?   = update?

  private

  def own_profile?
    record.user_id == user.id
  end
end
