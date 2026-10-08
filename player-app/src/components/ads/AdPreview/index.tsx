import { useState, useEffect } from "react"
import { AdRenderer } from "../AdRenderer"
import type { ManifestPlaylistAd } from "../../../types"

export function AdPreview() {
  const [ad, setAd] = useState<ManifestPlaylistAd | null>(null)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const params = new URLSearchParams(window.location.search)
    const pid = params.get("pid")
    if (!pid) {
      setError("No ad PID provided")
      return
    }

    fetch(`/preview-api/ads/${pid}/preview.json`, { credentials: "include" })
      .then((res) => {
        if (!res.ok) throw new Error(`${res.status} ${res.statusText}`)
        return res.json()
      })
      .then(setAd)
      .catch((err) => setError(err.message))
  }, [])

  if (error) {
    return (
      <div className="w-full h-full flex items-center justify-center bg-black text-white/50 text-sm">
        {error}
      </div>
    )
  }

  if (!ad) {
    return <div className="w-full h-full bg-black" />
  }

  return <AdRenderer ad={ad} />
}
