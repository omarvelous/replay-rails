class SettingsPolicy < ApplicationPolicy
  def show?
    agent_or_above?
  end

  def update?
    owner?
  end
end
