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

export function MosaicLandscape({ listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const photos = listing.photos

  return (
    <div className="flex w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Photos — left 64%, grid: 1 large + 2 stacked */}
      <div
        style={{
          width: "64%", display: "grid",
          gridTemplateColumns: "2fr 1fr", gridTemplateRows: "1fr 1fr",
          gap: "0.4cqw",
        }}
      >
        <div className="relative overflow-hidden" style={{ gridRow: "1 / -1" }}>
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

      {/* Text column — right 36% */}
      <div
        className="flex flex-col justify-between"
        style={{ width: "36%", padding: "var(--safe)" }}
      >
        <div>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          <div style={{ marginTop: "var(--gap-sm)" }}>
            <Address
              street={listing.street} city={listing.city}
              state={listing.state} neighborhood={listing.neighborhood}
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
          <div className="flex items-center" style={{ gap: "var(--gap)", marginTop: "var(--gap)" }}>
            <QrCode />
          </div>
          {agent && (
            <div style={{ marginTop: "var(--gap)" }}>
              <AgentStrip agent={agent} />
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
