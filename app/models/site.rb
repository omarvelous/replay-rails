class Site < ApplicationRecord
  has_paper_trail ignore: [ :updated_at ]
  belongs_to :account

  has_one_attached :photo do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 400, 225 ]
    attachable.variant :card,  resize_to_fill: [ 800, 450 ]
  end

  has_many :screens, dependent: :destroy

  validates :name, presence: true
end
