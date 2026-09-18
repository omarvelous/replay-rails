class LeadPolicy < ApplicationPolicy
  def show?    = manager_or_above? || owns_lead?
  def update?  = manager_or_above? || owns_lead?
  def destroy? = manager_or_above?

  scope_for :active_record_relation do |relation|
    if manager_or_above?
      relation
    else
      relation.joins(:lead_agents)
              .where(lead_agents: { agent_id: user.agent_profile&.id })
    end
  end

  private

  def owns_lead?
    user.agent_profile && record.current_agent == user.agent_profile
  end
end
