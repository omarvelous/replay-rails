class AgentPolicy < ApplicationPolicy
  def update? = manager_or_above? || own_profile?
  def edit?   = update?

  private

  def own_profile?
    record.user_id == user.id
  end
end
