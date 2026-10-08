import { Badge } from "../../../elements/Badge"
import { Address } from "../../../elements/Address"
import { StatBlock } from "../../../elements/StatBlock"
import { Price } from "../../../elements/Price"
import { AgentStrip } from "../../../elements/AgentStrip"
import { QrCode } from "../../../elements/QrCode"
import type { ManifestPlaylistAd, ManifestListingAd } from "../../../../../types"

interface Props {
  ad: ManifestPlaylistAd
  listingAd: ManifestListingAd
}

export function StatGridLandscape({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="flex w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Text column — left 60% */}
      <div
        className="flex flex-col justify-between"
        style={{ width: "60%", padding: "var(--safe)" }}
      >
        <div>
          <Badge badge={listingAd.badge} label={listingAd.badge_label} />
          <div style={{ marginTop: "var(--gap-sm)" }}>
            <Address
              street={listing.street} city={listing.city}
              state={listing.state} neighborhood={listing.neighborhood}
              address={listing.address}
              style={{ fontSize: "3cqw" }}
            />
          </div>
          <StatBlock beds={listing.beds} baths={listing.baths} sqft={listing.sqft} />
        </div>

        <div>
          <Price
            price={listing.price}
            originalPrice={listingAd.original_price}
            soldPrice={listingAd.sold_price}
            badge={listingAd.badge}
          />
          <div className="flex items-end justify-between" style={{ marginTop: "var(--gap)" }}>
            <QrCode />
            {agent && <AgentStrip agent={agent} />}
          </div>
        </div>
      </div>

      {/* Photo column — right 40% */}
      <div className="relative overflow-hidden" style={{ width: "40%" }}>
        {imageUrl ? (
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
        ) : (
          <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
        )}
      </div>
    </div>
  )
}
