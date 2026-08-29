class MetricSnapshot < ApplicationRecord
  acts_as_tenant :account

  validates :metric_name, :value, :starts_at, :ends_at, presence: true
end
