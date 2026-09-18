class LeadPolicy < ApplicationPolicy
  def show?    = account_user.at_least?("manager") || owns_lead?
  def update?  = account_user.at_least?("manager") || owns_lead?
  def destroy? = account_user.at_least?("manager")

  scope_for :active_record_relation do |relation|
    if account_user.at_least?("manager")
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
