class LeadPolicy < ApplicationPolicy
  def show?    = user.can_manage?(account) || owns_lead?
  def update?  = user.can_manage?(account) || owns_lead?
  def destroy? = user.can_manage?(account)

  scope_for :active_record_relation do |relation|
    if user.can_manage?(account)
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
