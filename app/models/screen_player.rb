class ScreenPlayer < ApplicationRecord
  has_paper_trail
  belongs_to :screen
  belongs_to :player
  belongs_to :paired_by, class_name: "User", optional: true

  scope :active, -> { where(active: true) }
  scope :history, -> { where(active: false) }

  def unpair!
    update!(active: false, unpaired_at: Time.current)
    ActionCable.server.broadcast("screen_#{screen_id}", { event: "unpaired" })
  end
end
