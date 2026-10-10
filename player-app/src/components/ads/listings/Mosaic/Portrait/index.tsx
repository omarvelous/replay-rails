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

export function MosaicPortrait({ listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const photos = listing.photos

  return (
    <div className="flex flex-col w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Photos — top 55%: 1 large on top, 2 side by side below */}
      <div
        style={{
          height: "55%",
          flexShrink: 0,
          display: "grid",
          gridTemplateColumns: "1fr 1fr",
          gridTemplateRows: "1.5fr 1fr",
          gap: "0.4cqw",
        }}
      >
        <div className="relative overflow-hidden" style={{ gridColumn: "1 / -1" }}>
          {photos[0] && <img src={photos[0].url} alt="" className="absolute inset-0 w-full h-full object-cover" />}
          {!photos[0] && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
        </div>
        <div className="relative overflow-hidden">
          {photos[1] && <img src={photos[1].url} alt="" className="absolute inset-0 w-full h-full object-cover" />}
          {!photos[1] && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
        </div>
        <div className="relative overflow-hidden">
          {photos[2] && <img src={photos[2].url} alt="" className="absolute inset-0 w-full h-full object-cover" />}
          {!photos[2] && <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />}
        </div>
      </div>

      {/* Text — bottom 45% */}
      <div className="flex flex-col justify-between" style={{ height: "45%", padding: "var(--safe)" }}>
        <div>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          <div style={{ marginTop: "var(--gap-sm)" }}>
            <Address
              street={listing.street}
              city={listing.city}
              state={listing.state}
              neighborhood={listing.neighborhood}
              address={listing.address}
            />
          </div>
          <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        </div>

        <div>
          <Price
            price={listing.price}
            originalPrice={listingAd.original_price}
            soldPrice={listingAd.sold_price}
            badge={listingAd.badge}
          />
          <div className="flex items-end justify-between" style={{ marginTop: "var(--gap)" }}>
            {agent ? <AgentStrip agent={agent} /> : <div />}
            <QrCode />
          </div>
        </div>
      </div>
    </div>
  )
}
