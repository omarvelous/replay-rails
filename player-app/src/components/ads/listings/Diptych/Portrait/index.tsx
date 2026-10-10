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

export function DiptychPortrait({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const photos = listing.photos
  const adImage = ad.images[0]?.url

  return (
    <div
      className="relative flex flex-col w-full h-full"
      style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}
    >
      {/* Two photos stacked, each 50% */}
      <div className="relative overflow-hidden" style={{ height: "50%" }}>
        {(photos[0] || adImage) && (
          <img src={photos[0]?.url || adImage} alt="" className="absolute inset-0 w-full h-full object-cover" />
        )}
        {!photos[0] && !adImage && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
      </div>
      <div className="relative overflow-hidden" style={{ height: "50%" }}>
        {photos[1] && <img src={photos[1].url} alt="" className="absolute inset-0 w-full h-full object-cover" />}
        {!photos[1] && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
      </div>

      {/* Badge top-left */}
      <div className="absolute" style={{ top: "var(--safe)", left: "var(--safe)", zIndex: 1 }}>
        <Badge badge={listingAd.badge} label={listingAd.badge_label} />
      </div>

      {/* Text bar straddling the seam at center */}
      <div
        className="absolute flex flex-col"
        style={{
          top: "50%",
          transform: "translateY(-50%)",
          left: "var(--safe)",
          right: "var(--safe)",
          padding: "1.6cqw 2cqw",
          background: "var(--ad-bg)",
          borderRadius: "0.5cqw",
          zIndex: 1,
          gap: "var(--gap-sm)",
        }}
      >
        <div>
          <Address
            street={listing.street}
            city={listing.city}
            state={listing.state}
            neighborhood={listing.neighborhood}
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

      {/* Agent bottom-left */}
      {agent && (
        <div className="absolute" style={{ bottom: "var(--safe)", left: "var(--safe)", zIndex: 1 }}>
          <AgentStrip agent={agent} pill />
        </div>
      )}
    </div>
  )
}
