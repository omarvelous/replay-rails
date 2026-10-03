import { HeroLayout } from "../layouts/HeroLayout"
import { SplitLayout } from "../layouts/SplitLayout"
import { MinimalLayout } from "../layouts/MinimalLayout"
import { StatGridLayout } from "../layouts/StatGridLayout"
import { Badge } from "../shared/Badge"
import { AgentStrip } from "../shared/AgentStrip"
import type { ManifestPlaylistAd, ManifestListingAd } from "../../../types"

interface ListingAdProps {
  ad: ManifestPlaylistAd
}

export function ListingAd({ ad }: ListingAdProps) {
  const listingAd = ad.adable as ManifestListingAd
  const imageUrl = ad.images[0]?.url

  const content = <ListingContent ad={ad} listingAd={listingAd} />
  const agentStrip = listingAd.agent ? <AgentStrip agent={listingAd.agent} /> : null

  switch (ad.layout) {
    case "split":
      return <SplitLayout imageUrl={imageUrl}>{content}{agentStrip}</SplitLayout>
    case "minimal":
      return <MinimalLayout>{content}{agentStrip}</MinimalLayout>
    case "stat_grid":
      return <StatGridLayout>{content}{agentStrip}</StatGridLayout>
    default: // hero
      return <HeroLayout imageUrl={imageUrl}>{content}{agentStrip}</HeroLayout>
  }
}

function ListingContent({ listingAd }: { ad: ManifestPlaylistAd; listingAd: ManifestListingAd }) {
  const listing = listingAd.listing

  const formatPrice = (price: number) =>
    new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(price)

  const specs = [
    listing.beds ? `${listing.beds} bd` : null,
    listing.baths ? `${listing.baths} ba` : null,
    listing.sqft ? `${listing.sqft.toLocaleString()} sqft` : null,
  ].filter(Boolean).join(" · ")

  return (
    <div>
      {listingAd.badge_label && (
        <div style={{ marginBottom: "var(--s-gap)" }}>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
        </div>
      )}

      <div className="flex items-baseline" style={{ gap: "var(--s-gap)" }}>
        <span className="font-extrabold tracking-tight leading-none" style={{ fontSize: "var(--s-hero)" }}>
          {formatPrice(listing.price)}
        </span>
        {listingAd.original_price && (
          <span className="line-through" style={{ fontSize: "var(--s-3xl)", color: "var(--ad-text-faint)" }}>
            {formatPrice(listingAd.original_price)}
          </span>
        )}
      </div>

      <div style={{ fontSize: "var(--s-3xl)", marginTop: "var(--s-gap)", color: "var(--ad-text-muted)" }}>
        {listing.address}
      </div>

      {specs && (
        <div style={{ fontSize: "var(--s-xl)", marginTop: "var(--s-xs)", color: "var(--ad-text-faint)" }}>
          {specs}
        </div>
      )}

      {listingAd.event_date && (
        <div
          className="inline-flex items-center rounded-xl font-bold"
          style={{ fontSize: "var(--s-2xl)", marginTop: "var(--s-gap)", padding: "var(--s-badge-py) var(--s-badge-px)", background: "var(--ad-surface)", color: "var(--ad-accent)" }}
        >
          {listingAd.event_date}
          {listingAd.event_start_time && ` · ${listingAd.event_start_time}`}
          {listingAd.event_end_time && ` – ${listingAd.event_end_time}`}
        </div>
      )}
    </div>
  )
}
