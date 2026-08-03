class Screen < ApplicationRecord
  belongs_to :site

  validates :name, presence: true
  validates :orientation, inclusion: { in: %w[landscape portrait] }
end
