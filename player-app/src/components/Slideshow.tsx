import { useState, useEffect, useCallback } from "react"
import { track } from "../analytics"
import type { ManifestResponse, ManifestPlaylist, ManifestPlaylistAd, ManifestListingAd } from "../types"

interface SlideshowProps {
  manifest: ManifestResponse
}

export function Slideshow({ manifest }: SlideshowProps) {
  const playlist = manifest.contentable as ManifestPlaylist
  const ads = playlist.playlist_ads

  const [currentIndex, setCurrentIndex] = useState(0)
  const [progress, setProgress] = useState(0)

  const advance = useCallback(() => {
    setCurrentIndex((i) => (i + 1) % ads.length)
    setProgress(0)
  }, [ads.length])

  const currentAd = ads[currentIndex]

  // Auto-advance timer
  useEffect(() => {
    if (!currentAd) return
    const duration = (currentAd.duration ?? 10) * 1000
    const timer = setTimeout(advance, duration)
    return () => clearTimeout(timer)
  }, [currentIndex, currentAd, advance])

  // Track impression when ad becomes visible
  useEffect(() => {
    if (!currentAd) return

    track("content.impressed", {
      ad_pid: currentAd.pid,
      screen_pid: manifest.screen_pid,
      screen_content_pid: manifest.screen_content?.pid,
      playlist_pid: playlist.pid,
      account_pid: manifest.account_pid,
      position: currentAd.position,
      duration: currentAd.duration,
    })
  }, [currentIndex, currentAd, manifest, playlist.pid])

  // Progress bar animation
  useEffect(() => {
    if (!currentAd) return
    const frame = requestAnimationFrame(() => setProgress(1))
    return () => cancelAnimationFrame(frame)
  }, [currentIndex, currentAd])

  if (!currentAd) return null

  const imageUrl = currentAd.images[0]?.url
  const duration = currentAd.duration ?? 10

  return (
    <div className="relative h-dvh w-full bg-black overflow-hidden">
      {imageUrl && (
        <img
          key={currentAd.pid}
          src={imageUrl}
          alt={currentAd.headline}
          className="absolute inset-0 w-full h-full object-cover"
        />
      )}

      <div className="absolute inset-0 bg-linear-to-t from-black/80 via-black/20 to-transparent" />

      <div className="absolute bottom-0 left-0 right-0 p-8 text-white">
        <AdContent ad={currentAd} />
      </div>

      <div className="absolute bottom-0 left-0 w-full h-1 bg-white/10" style={{ zIndex: 10 }}>
        <div
          className="h-full bg-white/50"
          style={{
            transform: `scaleX(${progress})`,
            transformOrigin: "left",
            transition: progress === 0 ? "none" : `transform ${duration}s linear`,
          }}
        />
      </div>
    </div>
  )
}

function AdContent({ ad }: { ad: ManifestPlaylistAd }) {
  const adable = ad.adable

  if (adable.type === "Ads::ListingAd") {
    return <ListingAdContent listingAd={adable} />
  }

  if (adable.type === "Ads::AgentAd") {
    const agent = adable.agent
    return (
      <div className="flex items-center gap-6">
        {agent.photos[0] && (
          <img src={agent.photos[0].url} alt={agent.name} className="w-20 h-20 rounded-full object-cover" />
        )}
        <div>
          <p className="text-sm uppercase tracking-widest text-indigo-400 font-bold">Your Agent</p>
          <h2 className="text-4xl font-extrabold tracking-tight">{agent.name}</h2>
          {ad.body && <p className="text-lg text-white/70 mt-1">{ad.body}</p>}
        </div>
      </div>
    )
  }

  return (
    <div>
      <h2 className="text-4xl font-extrabold tracking-tight">{ad.headline}</h2>
      {ad.body && <p className="text-lg text-white/70 mt-2">{ad.body}</p>}
    </div>
  )
}

function ListingAdContent({ listingAd }: { listingAd: ManifestListingAd }) {
  const listing = listingAd.listing

  const formatPrice = (price: number) =>
    new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(price)

  const specs = [
    listing.beds ? `${listing.beds} bd` : null,
    listing.baths ? `${listing.baths} ba` : null,
    listing.sqft ? `${listing.sqft.toLocaleString()} sqft` : null,
  ].filter(Boolean).join(" · ")

  return (
    <div>
      {listingAd.badge_label && (
        <div className="mb-3">
          <span className="inline-flex items-center rounded-full bg-green-500 px-3 py-1 text-sm font-bold text-white uppercase tracking-wider">
            {listingAd.badge_label}
          </span>
        </div>
      )}

      <div className="flex items-baseline gap-3">
        <span className="text-5xl font-extrabold tracking-tight">{formatPrice(listing.price)}</span>
        {listingAd.original_price && (
          <span className="text-2xl line-through text-white/40">{formatPrice(listingAd.original_price)}</span>
        )}
      </div>

      <p className="text-2xl text-white/70 mt-2">{listing.address}</p>

      {specs && <p className="text-lg text-white/50 mt-1">{specs}</p>}

      {listingAd.event_date && (
        <div className="inline-flex items-center rounded-xl bg-white/10 px-4 py-2 mt-3 text-lg font-bold text-amber-400">
          {listingAd.event_date}
          {listingAd.event_start_time && ` · ${listingAd.event_start_time}`}
          {listingAd.event_end_time && ` – ${listingAd.event_end_time}`}
        </div>
      )}

      {listingAd.agent && (
        <div className="flex items-center gap-3 mt-4">
          {listingAd.agent.photos[0] && (
            <img src={listingAd.agent.photos[0].url} alt={listingAd.agent.name} className="w-10 h-10 rounded-full object-cover" />
          )}
          <div>
            <p className="text-sm font-semibold">{listingAd.agent.name}</p>
            <p className="text-xs text-white/50">{listingAd.agent.phone || listingAd.agent.email}</p>
          </div>
        </div>
      )}
    </div>
  )
}
