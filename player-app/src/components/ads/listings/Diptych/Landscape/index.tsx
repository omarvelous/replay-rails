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

export function DiptychLandscape({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const photos = listing.photos
  const adImage = ad.images[0]?.url

  return (
    <div className="relative flex w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Two photos side by side, no gutter */}
      <div className="relative overflow-hidden" style={{ width: "50%" }}>
        {(photos[0] || adImage) && (
          <img src={photos[0]?.url || adImage} alt="" className="absolute inset-0 w-full h-full object-cover" />
        )}
        {!photos[0] && !adImage && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
      </div>
      <div className="relative overflow-hidden" style={{ width: "50%" }}>
        {photos[1] && <img src={photos[1].url} alt="" className="absolute inset-0 w-full h-full object-cover" />}
        {!photos[1] && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
      </div>

      {/* Badge top-left */}
      <div className="absolute" style={{ top: "var(--safe)", left: "var(--safe)", zIndex: 1 }}>
        <Badge badge={listingAd.badge} label={listingAd.badge_label} />
      </div>

      {/* Agent top-right */}
      {agent && (
        <div className="absolute" style={{ top: "var(--safe)", right: "var(--safe)", zIndex: 1 }}>
          <AgentStrip agent={agent} pill />
        </div>
      )}

      {/* Text bar bridging the seam */}
      <div
        className="absolute flex items-center justify-between"
        style={{
          bottom: "var(--safe)", left: "50%", transform: "translateX(-50%)",
          width: "72cqw", padding: "1.6cqw 2cqw",
          background: "var(--ad-bg)", borderRadius: "0.5cqw", zIndex: 1,
        }}
      >
        <div>
          <Address
            street={listing.street} city={listing.city}
            state={listing.state} neighborhood={listing.neighborhood}
            address={listing.address}
          />
          <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        </div>
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
