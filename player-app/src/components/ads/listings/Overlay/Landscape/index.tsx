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

export function OverlayLandscape({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent

  return (
    <div className="relative w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      <PhotoWrap src={ad.images[0]?.url} scrim />

      {/* Top row: agent left, QR right */}
      <div
        className="absolute flex justify-between items-start"
        style={{ top: "var(--safe)", left: "var(--safe)", right: "var(--safe)", zIndex: 1 }}
      >
        {agent ? <AgentStrip agent={agent} pill /> : <div />}
        <QrCode />
      </div>

      {/* Bottom content */}
      <div
        className="relative flex flex-col justify-end h-full"
        style={{ padding: "var(--safe)" }}
      >
        <div style={{ maxWidth: "58cqw" }}>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          <div style={{ marginTop: "var(--gap-sm)" }}>
            <Address street={listing.street} city={listing.city} state={listing.state} neighborhood={listing.neighborhood} address={listing.address} />
          </div>
          <Specs beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
          <div style={{ marginTop: "calc(var(--gap) * 2)" }}>
            <Price
              price={listing.price}
              originalPrice={listingAd.original_price}
              soldPrice={listingAd.sold_price}
              badge={listingAd.badge}
            />
          </div>
        </div>
      </div>
    </div>
  )
}
