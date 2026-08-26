class AddListingToLeads < ActiveRecord::Migration[8.1]
  def change
    add_reference :leads, :listing, foreign_key: true
  end
end
