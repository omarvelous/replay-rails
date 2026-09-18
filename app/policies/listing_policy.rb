class ListingPolicy < ApplicationPolicy
  def show?
    manager_or_above? || owns_listing?
  end

  scope_for :active_record_relation do |relation|
    if manager_or_above?
      relation
    else
      relation.joins(:listing_agents)
              .where(listing_agents: { agent_id: user.agent_profile&.id })
    end
  end

  private

  def owns_listing?
    record.listing_agents.exists?(agent_id: user.agent_profile&.id)
  end
end
