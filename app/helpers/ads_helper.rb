module AdsHelper
  THEME_OVERRIDES = {
    "dark" => {},
    "light" => {
      "--ad-bg"         => "#f9fafb",
      "--ad-text"       => "#111827",
      "--ad-text-muted" => "#4b5563",
      "--ad-text-faint" => "#6b7280",
      "--ad-accent"     => "#2f6bff",
      "--ad-surface"    => "#ffffff"
    },
    "brand" => {
      "--ad-bg"         => :accent,
      "--ad-text"       => "#ffffff",
      "--ad-text-muted" => "rgba(255, 255, 255, 0.65)",
      "--ad-text-faint" => "rgba(255, 255, 255, 0.5)",
      "--ad-surface"    => "rgba(255, 255, 255, 0.1)"
    }
  }.freeze

  def ad_theme_style(theme, accent: "#2f6bff")
    overrides = THEME_OVERRIDES.fetch(theme, {})
    overrides
      .map { |k, v| "#{k}: #{v == :accent ? accent : v}" }
      .join("; ")
  end

  def edit_typed_ad_path(ad)
    # Uses namespaced routes when available (Phase E), falls back to base route
    route = "edit_ads_#{ad.adable_short_name}_path"
    respond_to?(route, true) ? send(route, ad) : edit_ad_path(ad)
  end
end
