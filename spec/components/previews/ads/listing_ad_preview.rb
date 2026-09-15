class Ads::ListingAdPreview < ViewComponent::Preview
  layout "lookbook_preview"

  # @label Hero — Just Listed
  def hero_just_listed
    render_with_template(locals: { ad: build_ad("just_listed", "hero") })
  end

  # @label Hero — Open House
  def hero_open_house
    render_with_template(locals: { ad: build_ad("open_house", "hero", event_date: Date.tomorrow, event_start_time: Time.zone.parse("13:00"), event_end_time: Time.zone.parse("15:00")) })
  end

  # @label Hero — Just Sold
  def hero_just_sold
    render_with_template(locals: { ad: build_ad("just_sold", "hero", sold_price: 2_400_000) })
  end

  # @label Hero — Price Reduction
  def hero_price_reduction
    render_with_template(locals: { ad: build_ad("price_reduction", "hero", original_price: 2_800_000) })
  end

  # @label Split
  def split
    render_with_template(locals: { ad: build_ad("just_listed", "split") })
  end

  # @label Minimal
  def minimal
    render_with_template(locals: { ad: build_ad("just_listed", "minimal") })
  end

  # @label Stat Grid
  def stat_grid
    render_with_template(locals: { ad: build_ad("just_listed", "stat_grid") })
  end

  private

  def build_ad(badge, layout, **extra)
    listing = FactoryBot.build(:listing, address: "350 Fifth Ave, New York, NY 10118", price: 2_500_000, beds: 3, baths: 2, sqft: 2200)
    listing_ad = FactoryBot.build(:listing_ad, listing: listing, badge: badge, **extra)
    FactoryBot.build(:ad, adable: listing_ad, headline: Ads::ListingAd::BADGE_LABELS[badge], layout: layout, theme: "dark")
  end
end
