class Ads::BrandAdPreview < ViewComponent::Preview
  layout "lookbook_preview"

  # @label Hero — Dark
  def hero_dark
    render_with_template(locals: { ad: build_ad("hero", "dark") })
  end

  # @label Hero — Brand
  def hero_brand
    render_with_template(locals: { ad: build_ad("hero", "brand") })
  end

  # @label Minimal — Dark
  def minimal_dark
    render_with_template(locals: { ad: build_ad("minimal", "dark") })
  end

  # @label Minimal — Light
  def minimal_light
    render_with_template(locals: { ad: build_ad("minimal", "light") })
  end

  private

  def build_ad(layout, theme)
    brand_ad = FactoryBot.build(:brand_ad)
    FactoryBot.build(:ad, adable: brand_ad, headline: "Your Window, Working 24/7", layout: layout, theme: theme)
  end
end
