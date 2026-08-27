class MetricSnapshot < ApplicationRecord
  belongs_to :account

  validates :metric_name, :value, :starts_at, :ends_at, presence: true
end
