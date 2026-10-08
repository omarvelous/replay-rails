class RenameHeroToOverlayOnAds < ActiveRecord::Migration[8.1]
  def up
    Ad.where(layout: "hero").update_all(layout: "overlay")
  end

  def down
    Ad.where(layout: "overlay").update_all(layout: "hero")
  end
end
