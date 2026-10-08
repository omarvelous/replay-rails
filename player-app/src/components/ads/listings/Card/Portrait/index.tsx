import { Badge } from "../../../elements/Badge"
import { Address } from "../../../elements/Address"
import { Specs } from "../../../elements/Specs"
import { Price } from "../../../elements/Price"
import { AgentStrip } from "../../../elements/AgentStrip"
import { QrCode } from "../../../elements/QrCode"
import type { ManifestPlaylistAd, ManifestListingAd } from "../../../../../types"

interface Props {
  ad: ManifestPlaylistAd
  listingAd: ManifestListingAd
}

export function CardPortrait({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="relative w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Full-bleed photo, no scrim */}
      {imageUrl ? (
        <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
      ) : (
        <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
      )}

      {/* Card — full width, bottom-anchored, up to 50% height */}
      <div
        className="absolute flex flex-col"
        style={{
          bottom: "var(--safe)", left: "var(--safe)", right: "var(--safe)",
          maxHeight: "50%", padding: "calc(var(--gap) * 1.5)",
          background: "var(--ad-surface)", borderRadius: "0.8cqw",
          gap: "var(--gap-sm)",
        }}
      >
        {agent && (
          <div style={{ marginBottom: "var(--gap-sm)" }}>
            <AgentStrip agent={agent} />
          </div>
        )}
        <Badge badge={listingAd.badge} label={listingAd.badge_label} />
        <Address
          street={listing.street} city={listing.city}
          state={listing.state} neighborhood={listing.neighborhood}
          address={listing.address}
        />
        <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        <div className="flex items-end justify-between" style={{ marginTop: "var(--gap)" }}>
          <Price
            price={listing.price}
            originalPrice={listingAd.original_price}
            soldPrice={listingAd.sold_price}
            badge={listingAd.badge}
          />
          <QrCode />
        </div>
      </div>
    </div>
  )
}
