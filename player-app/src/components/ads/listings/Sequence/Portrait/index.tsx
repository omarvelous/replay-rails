import { PhotoWrap } from "../../../elements/PhotoWrap"
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

export function SequencePortrait({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const photos = listing.photos
  const photoUrl = photos[0]?.url || ad.images[0]?.url

  return (
    <div className="relative w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      <PhotoWrap src={photoUrl} scrim />

      {/* Top row: agent left, QR right */}
      <div
        className="absolute flex justify-between items-start"
        style={{ top: "var(--safe)", left: "var(--safe)", right: "var(--safe)", zIndex: 1 }}
      >
        {agent ? <AgentStrip agent={agent} pill /> : <div />}
        <QrCode />
      </div>

      {/* Bottom content — stacked full-width */}
      <div
        className="relative flex flex-col justify-end h-full"
        style={{ padding: "var(--safe)" }}
      >
        {/* Progress ticks */}
        <div className="flex" style={{ gap: "0.4cqw", marginBottom: "var(--gap-sm)" }}>
          {photos.slice(0, 3).map((_, i) => (
            <div
              key={i}
              style={{
                width: "2.4cqw", height: "0.2cqw", borderRadius: "0.1cqw",
                background: i === 0 ? "var(--ad-accent)" : "var(--ad-text-faint)",
              }}
            />
          ))}
          {photos.length === 0 && <div style={{ width: "2.4cqw", height: "0.2cqw", borderRadius: "0.1cqw", background: "var(--ad-accent)" }} />}
        </div>

        <Badge badge={listingAd.badge} label={listingAd.badge_label} />
        <div style={{ marginTop: "var(--gap-sm)" }}>
          <Address
            street={listing.street} city={listing.city}
            state={listing.state} neighborhood={listing.neighborhood}
            address={listing.address}
          />
        </div>
        <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        <div style={{ marginTop: "calc(var(--gap) * 3)" }}>
          <Price
            price={listing.price}
            originalPrice={listingAd.original_price}
            soldPrice={listingAd.sold_price}
            badge={listingAd.badge}
          />
        </div>
      </div>
    </div>
  )
}
