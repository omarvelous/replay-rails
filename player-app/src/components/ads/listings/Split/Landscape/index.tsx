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

export function SplitLandscape({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="flex w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Photo column — 58% */}
      <div className="relative overflow-hidden" style={{ width: "58%", flexShrink: 0 }}>
        {imageUrl ? (
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
        ) : (
          <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
        )}
        {/* QR upper-right on photo */}
        <div className="absolute" style={{ top: "var(--safe)", right: "var(--safe)", zIndex: 1 }}>
          <QrCode />
        </div>
      </div>

      {/* Text column — 42% */}
      <div
        className="flex flex-col justify-between"
        style={{ width: "42%", padding: "var(--safe)" }}
      >
        {/* Top: listing details */}
        <div>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          <div style={{ marginTop: "var(--gap-sm)" }}>
            <Address street={listing.street} city={listing.city} state={listing.state} neighborhood={listing.neighborhood} address={listing.address} />
          </div>
          <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        </div>

        {/* Bottom: price + agent */}
        <div>
          <Price
            price={listing.price}
            originalPrice={listingAd.original_price}
            soldPrice={listingAd.sold_price}
            badge={listingAd.badge}
          />
          {agent && (
            <div style={{ marginTop: "var(--gap)", paddingTop: "var(--gap)", borderTop: "1px solid var(--ad-text-faint)" }}>
              <AgentStrip agent={agent} />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
