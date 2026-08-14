class ScreenPlayer < ApplicationRecord
  belongs_to :screen
  belongs_to :player
  belongs_to :paired_by, class_name: "User", optional: true

  scope :active, -> { where(active: true) }
  scope :history, -> { where(active: false) }

  def unpair!
    update!(active: false, unpaired_at: Time.current)
  end
end
