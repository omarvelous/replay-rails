class NamespaceAdableTypes < ActiveRecord::Migration[8.1]
  def up
    {
      "ListingAd"      => "Ads::ListingAd",
      "CollectionAd"   => "Ads::CollectionAd",
      "AgentAd"        => "Ads::AgentAd",
      "BrandAd"        => "Ads::BrandAd"
    }.each do |old_type, new_type|
      Ad.where(adable_type: old_type).update_all(adable_type: new_type)
    end
  end

  def down
    {
      "Ads::ListingAd"      => "ListingAd",
      "Ads::CollectionAd"   => "CollectionAd",
      "Ads::AgentAd"        => "AgentAd",
      "Ads::BrandAd"        => "BrandAd"
    }.each do |old_type, new_type|
      Ad.where(adable_type: old_type).update_all(adable_type: new_type)
    end
  end
end
