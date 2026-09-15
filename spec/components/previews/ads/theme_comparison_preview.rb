class Ads::ThemeComparisonPreview < ViewComponent::Preview
  layout "lookbook_preview"

  # @label Dark vs Light — Hero
  def dark_vs_light_hero
    render_with_template(locals: {
      dark_ad: build_brand_ad("hero", "dark"),
      light_ad: build_brand_ad("hero", "light")
    })
  end

  # @label Dark vs Light — Minimal
  def dark_vs_light_minimal
    render_with_template(locals: {
      dark_ad: build_brand_ad("minimal", "dark"),
      light_ad: build_brand_ad("minimal", "light")
    })
  end

  # @label Dark vs Brand — Hero
  def dark_vs_brand_hero
    render_with_template(locals: {
      dark_ad: build_brand_ad("hero", "dark"),
      light_ad: build_brand_ad("hero", "brand")
    })
  end

  private

  def build_brand_ad(layout, theme)
    brand_ad = FactoryBot.build(:brand_ad)
    FactoryBot.build(:ad, adable: brand_ad, headline: "Your Window, Working 24/7", layout: layout, theme: theme)
  end
end
