import { GridLayout } from "../layouts/GridLayout"
import type { ManifestPlaylistAd, ManifestCollectionAd, ManifestListingAd } from "../../../types"

interface CollectionAdProps {
  ad: ManifestPlaylistAd
}

export function CollectionAd({ ad }: CollectionAdProps) {
  const collectionAd = ad.adable as ManifestCollectionAd
  const items = collectionAd.collection_ads
  const cols = items.length > 4 ? 3 : 2

  return (
    <GridLayout>
      <div className="font-bold" style={{ fontSize: "var(--s-4xl)", marginBottom: "var(--s-xs)" }}>
        {ad.headline}
      </div>
      <div style={{ fontSize: "var(--s-xl)", marginBottom: "var(--s-gap)", color: "var(--ad-text-faint)" }}>
        {items.length} properties
      </div>

      <div className="grid flex-1" style={{ gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: "var(--s-gap)" }}>
        {items.map((item) => (
          <CollectionCard key={item.pid} item={item} />
        ))}
      </div>
    </GridLayout>
  )
}

function CollectionCard({ item }: { item: ManifestPlaylistAd }) {
  const imageUrl = item.images[0]?.url
  const isListingAd = item.adable.type === "Ads::ListingAd"
  const listingAd = isListingAd ? (item.adable as ManifestListingAd) : null
  const listing = listingAd?.listing

  const formatPrice = (price: number) =>
    new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(price)

  const specs = listing ? [
    listing.beds ? `${listing.beds} bd` : null,
    listing.baths ? `${listing.baths} ba` : null,
    listing.sqft ? `${listing.sqft.toLocaleString()} sqft` : null,
  ].filter(Boolean).join(" · ") : null

  return (
    <div className="rounded-2xl overflow-hidden flex flex-col" style={{ background: "var(--ad-surface)" }}>
      <div className="flex-1 relative overflow-hidden" style={{ minHeight: "45%", background: "color-mix(in srgb, var(--ad-accent) 15%, transparent)" }}>
        {imageUrl && (
          <img src={imageUrl} alt={item.headline} className="absolute inset-0 w-full h-full object-cover" />
        )}
      </div>
      <div style={{ padding: "var(--s-pad)" }}>
        {listing ? (
          <>
            <div className="font-extrabold tracking-tight" style={{ fontSize: "var(--s-3xl)" }}>
              {formatPrice(listing.price)}
            </div>
            <div style={{ fontSize: "var(--s-lg)", marginTop: "var(--s-xs)", color: "var(--ad-text-muted)" }}>
              {listing.address}
            </div>
            {specs && (
              <div style={{ fontSize: "var(--s-base)", marginTop: "var(--s-xs)", color: "var(--ad-text-faint)" }}>
                {specs}
              </div>
            )}
          </>
        ) : (
          <div className="font-bold" style={{ fontSize: "var(--s-2xl)" }}>{item.headline}</div>
        )}
      </div>
    </div>
  )
}
