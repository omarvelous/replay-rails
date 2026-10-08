import { AdRenderer } from "../AdRenderer"
import type { ManifestPlaylistAd } from "../../../types"

export function AdPreview() {
  const hash = window.location.hash.slice(1)
  if (!hash) {
    return <div className="w-full h-full bg-black" />
  }

  const ad: ManifestPlaylistAd = JSON.parse(atob(hash))
  return <AdRenderer ad={ad} />
}
