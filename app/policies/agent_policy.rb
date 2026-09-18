class AgentPolicy < ApplicationPolicy
  def update? = account_user.at_least?("manager") || own_profile?
  def edit?   = update?

  private

  def own_profile?
    record.user_id == user.id
  end
end
