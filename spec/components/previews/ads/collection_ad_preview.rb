class Ads::CollectionAdPreview < ViewComponent::Preview
  layout "lookbook_preview"

  # @label Grid — Dark
  def grid_dark
    render_with_template(locals: { ad: build_ad("dark") })
  end

  # @label Grid — Light
  def grid_light
    render_with_template(locals: { ad: build_ad("light") })
  end

  private

  def build_ad(theme)
    collection_ad = FactoryBot.build(:collection_ad)
    FactoryBot.build(:ad, adable: collection_ad, headline: "Featured Listings", layout: "grid", theme: theme)
  end
end
