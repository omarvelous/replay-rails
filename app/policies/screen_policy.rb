class ScreenPolicy < ApplicationPolicy
  scope_for :active_record_relation do |relation|
    relation.joins(:site).where(sites: { account_id: account.id })
  end
end
