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

export function StatGridPortrait({ ad, listingAd }: Props) {
  const listing = listingAd.listing
  const agent = listingAd.agent
  const imageUrl = ad.images[0]?.url

  return (
    <div className="flex flex-col w-full h-full" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {/* Photo — top 36% */}
      <div className="relative overflow-hidden" style={{ height: "36%", flexShrink: 0 }}>
        {imageUrl ? (
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
        ) : (
          <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
        )}
      </div>

      {/* Content — bottom 64% */}
      <div className="flex flex-col justify-between" style={{ height: "64%", padding: "var(--safe)" }}>
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
            {agent ? <AgentStrip agent={agent} /> : <div />}
            <QrCode />
          </div>
        </div>
      </div>
    </div>
  )
}
