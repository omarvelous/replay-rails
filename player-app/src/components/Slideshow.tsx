import { useState, useEffect, useCallback } from "react"
import type { ManifestAd } from "../types"

interface SlideshowProps {
  ads: ManifestAd[]
}

export function Slideshow({ ads }: SlideshowProps) {
  const [currentIndex, setCurrentIndex] = useState(0)

  const advance = useCallback(() => {
    setCurrentIndex((i) => (i + 1) % ads.length)
  }, [ads.length])

  const currentAd = ads[currentIndex]

  useEffect(() => {
    if (!currentAd) return
    const timer = setTimeout(advance, currentAd.duration * 1000)
    return () => clearTimeout(timer)
  }, [currentIndex, currentAd, advance])

  if (!currentAd) return null

  return (
    <div className="relative h-dvh w-full bg-black overflow-hidden">
      {currentAd.image_url && (
        <img
          key={currentAd.pid}
          src={currentAd.image_url}
          alt={currentAd.headline}
          className="absolute inset-0 w-full h-full object-cover"
        />
      )}
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
      <div className="absolute bottom-0 left-0 right-0 p-8 text-white">
        <h2 className="text-4xl font-bold">{currentAd.headline}</h2>
        {currentAd.body && (
          <p className="text-lg text-white/80 mt-2">{currentAd.body}</p>
        )}
      </div>
    </div>
  )
}
