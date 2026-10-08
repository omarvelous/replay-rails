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

export function BandPortrait({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="flex flex-col w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Photo — top 58% */}
      <div className="relative overflow-hidden" style={{ height: "58%", flexShrink: 0 }}>
        {imageUrl ? (
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
        ) : (
          <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
        )}
        <div
          className="absolute flex justify-between items-start"
          style={{ top: "var(--safe)", left: "var(--safe)", right: "var(--safe)" }}
        >
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          {agent && <AgentStrip agent={agent} pill />}
        </div>
      </div>

      {/* Band — bottom 42%, stacked */}
      <div
        className="flex flex-col justify-between"
        style={{ height: "42%", padding: "var(--safe)" }}
      >
        <div>
          <Address
            street={listing.street} city={listing.city}
            state={listing.state} neighborhood={listing.neighborhood}
            address={listing.address}
          />
          <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        </div>
        <div className="flex items-end justify-between">
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
