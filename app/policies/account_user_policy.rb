class AccountUserPolicy < ApplicationPolicy
  scope_for :active_record_relation do |relation|
    relation.where(account: account)
  end
end
