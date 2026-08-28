class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def paper_trail_metadata
    { account_id: Current.account&.id || try(:account_id) || try(:account)&.id }
  end
end
