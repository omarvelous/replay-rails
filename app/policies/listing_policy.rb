class ListingPolicy < ApplicationPolicy
  def show?
    user.can_manage?(account) || owns_listing?
  end

  scope_for :active_record_relation do |relation|
    if user.can_manage?(account)
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
