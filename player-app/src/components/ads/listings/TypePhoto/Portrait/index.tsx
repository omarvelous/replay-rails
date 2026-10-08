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

export function TypePhotoPortrait({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="relative w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Optional photo as texture under wash */}
      {imageUrl && (
        <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
      )}
      <div className="absolute inset-0" style={{ background: "var(--ad-bg)", opacity: 0.78 }} />

      {/* Content — stacked, centered vertically */}
      <div
        className="relative flex flex-col justify-between h-full"
        style={{ padding: "var(--safe)" }}
      >
        {/* Top: badge */}
        <div>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
        </div>

        {/* Middle: large address + specs + price */}
        <div>
          <Address
            street={listing.street} city={listing.city}
            state={listing.state} neighborhood={listing.neighborhood}
            address={listing.address}
            style={{ fontSize: "9.6cqw" }}
          />
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

        {/* Bottom: agent left, QR right */}
        <div className="flex items-end justify-between">
          {agent ? <AgentStrip agent={agent} /> : <div />}
          <QrCode />
        </div>
      </div>
    </div>
  )
}
