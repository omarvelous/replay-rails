import type { ManifestExperience } from "../types"

interface ExperienceProps {
  experience: ManifestExperience
}

export function Experience({ experience }: ExperienceProps) {
  const { listing, agent } = experience

  return (
    <div className="h-dvh w-full bg-black text-white overflow-hidden flex flex-col">
      {/* Photos */}
      {listing.photos.length > 0 && (
        <div className="relative flex-1 min-h-0">
          <img
            src={listing.photos[0]}
            alt={listing.address}
            className="w-full h-full object-cover"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-transparent to-transparent" />
        </div>
      )}

      {/* Details */}
      <div className="p-8 space-y-4">
        <h1 className="text-3xl font-bold">{listing.address}</h1>
        <p className="text-2xl font-semibold text-indigo-400">
          ${listing.price.toLocaleString()}
        </p>
        <div className="flex gap-6 text-lg text-white/70">
          <span>{listing.beds} bed</span>
          <span>{listing.baths} bath</span>
          <span>{listing.sqft.toLocaleString()} sqft</span>
        </div>

        {/* Agent card */}
        {agent && (
          <div className="flex items-center gap-4 pt-4 border-t border-white/10">
            {agent.photo_url && (
              <img
                src={agent.photo_url}
                alt={agent.name}
                className="w-12 h-12 rounded-full object-cover"
              />
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
