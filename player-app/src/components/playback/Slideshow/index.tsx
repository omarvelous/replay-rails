import { useState, useEffect, useCallback } from "react"
import { track } from "../../../analytics"
import { AdRenderer } from "../../ads/AdRenderer"
import type { ManifestResponse, ManifestPlaylist } from "../../../types"

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

  // Track impression when ad becomes visible — currentIndex only, manifest
  // values are stable for the lifetime of a Slideshow instance
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
  }, [currentIndex]) // eslint-disable-line react-hooks/exhaustive-deps

  // Progress bar animation
  useEffect(() => {
    if (!currentAd) return
    const frame = requestAnimationFrame(() => setProgress(1))
    return () => cancelAnimationFrame(frame)
  }, [currentIndex, currentAd])

  if (!currentAd) return null

  const duration = currentAd.duration ?? 10

  return (
    <div className="relative h-dvh w-full bg-black overflow-hidden">
      <AdRenderer key={currentAd.pid} ad={currentAd} />

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
