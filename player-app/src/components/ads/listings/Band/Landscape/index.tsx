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

export function BandLandscape({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="flex flex-col w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Photo — top 68% */}
      <div className="relative overflow-hidden" style={{ height: "68%", flexShrink: 0 }}>
        {imageUrl ? (
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
        ) : (
          <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
        )}
        {/* Badge top-left, Agent top-right on photo */}
        <div
          className="absolute flex justify-between items-start"
          style={{ top: "var(--safe)", left: "var(--safe)", right: "var(--safe)" }}
        >
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          {agent && <AgentStrip agent={agent} pill />}
        </div>
      </div>

      {/* Band — bottom 32% */}
      <div
        className="flex items-center"
        style={{ height: "32%", padding: "0 var(--safe)", gap: "calc(var(--gap) * 2)" }}
      >
        {/* Left: address + specs */}
        <div style={{ flex: 1, minWidth: 0 }}>
          <Address
            street={listing.street} city={listing.city}
            state={listing.state} neighborhood={listing.neighborhood}
            address={listing.address}
          />
          <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        </div>
        {/* Right: price + QR */}
        <div className="flex items-center" style={{ gap: "var(--gap)", flexShrink: 0 }}>
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
