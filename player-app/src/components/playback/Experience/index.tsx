import type { ManifestResponse, ManifestExperience } from "../../../types"

interface ExperienceProps {
  manifest: ManifestResponse
}

export function Experience({ manifest }: ExperienceProps) {
  const experience = manifest.contentable as ManifestExperience
  const listingExp = experience.experienceable
  const listing = listingExp.listing
  const agent = listingExp.agent

  const formatPrice = (price: number) =>
    new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(price)

  const specs = [
    listing.beds ? `${listing.beds} bed` : null,
    listing.baths ? `${listing.baths} bath` : null,
    listing.sqft ? `${listing.sqft.toLocaleString()} sqft` : null,
  ]
    .filter(Boolean)
    .join(" · ")

  return (
    <div className="h-dvh w-full bg-black text-white overflow-hidden flex flex-col">
      {listing.photos.length > 0 && (
        <div className="relative flex-1 min-h-0">
          <img src={listing.photos[0].url} alt={listing.address} className="w-full h-full object-cover" />
          <div className="absolute inset-0 bg-linear-to-t from-black/80 via-transparent to-transparent" />
        </div>
      )}

      <div className="p-8 space-y-4">
        <h1 className="text-3xl font-bold">{listing.address}</h1>
        <p className="text-2xl font-semibold text-indigo-400">{formatPrice(listing.price)}</p>
        {specs && <p className="text-lg text-white/70">{specs}</p>}

        {agent && (
          <div className="flex items-center gap-4 pt-4 border-t border-white/10">
            {agent.photos[0] && (
              <img src={agent.photos[0].url} alt={agent.name} className="w-12 h-12 rounded-full object-cover" />
            )}
            <div>
              <p className="font-semibold">{agent.name}</p>
              <p className="text-sm text-white/50">{agent.phone || agent.email}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
