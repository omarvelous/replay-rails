class LeadPolicy < ApplicationPolicy
  def show?    = account_user.can_manage? || owns_lead?
  def update?  = account_user.can_manage? || owns_lead?
  def destroy? = account_user.can_manage?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if account_user.can_manage?
        scope.all
      else
        scope.joins(:lead_agents)
             .where(lead_agents: { agent_id: agent_id })
      end
    end

    private

    def agent_id
      account_user.user.agent_profile&.id
    end
  end

  private

  def owns_lead?
    agent = account_user.user.agent_profile
    agent.present? && record.current_agent == agent
  end
end
