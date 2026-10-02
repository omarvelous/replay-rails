import { useState, useEffect, useCallback } from "react"
import type { ManifestResponse } from "../queries/useManifestQuery"

interface SlideshowProps {
  manifest: ManifestResponse
}

interface PlaylistAd {
  pid: string
  position: number
  duration: number
  pid_ad?: string
  layout?: string
  theme?: string
  [key: string]: unknown
}

export function Slideshow({ manifest }: SlideshowProps) {
  const contentable = manifest.contentable as { playlist_ads?: PlaylistAd[] } | null
  const ads = contentable?.playlist_ads ?? []

  const [currentIndex, setCurrentIndex] = useState(0)

  const advance = useCallback(() => {
    setCurrentIndex((i) => (i + 1) % ads.length)
  }, [ads.length])

  const currentAd = ads[currentIndex]

  useEffect(() => {
    if (!currentAd) return
    const duration = (currentAd.duration ?? 10) * 1000
    const timer = setTimeout(advance, duration)
    return () => clearTimeout(timer)
  }, [currentIndex, currentAd, advance])

  if (!currentAd) return null

  return (
    <div className="relative h-dvh w-full bg-black overflow-hidden">
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
      <div className="absolute bottom-0 left-0 right-0 p-8 text-white">
        <p className="text-sm text-white/40 uppercase tracking-wider">
          {currentIndex + 1} / {ads.length}
        </p>
      </div>
    </div>
  )
}
