class LeadAgent < ApplicationRecord
  has_paper_trail
  belongs_to :lead
  belongs_to :agent
end
