import type { ManifestResponse, ManifestPlaylist, ManifestPlaylistAd } from "../types"

export async function preloadManifestImages(manifest: ManifestResponse): Promise<void> {
  const urls = extractImageUrls(manifest)
  if (urls.length === 0) return

  await Promise.all(
    urls.map(
      (url) =>
        new Promise<void>((resolve) => {
          const img = new Image()
          img.onload = img.onerror = () => resolve()
          img.src = url
        }),
    ),
  )
}

function extractImageUrls(manifest: ManifestResponse): string[] {
  const urls: string[] = []
  const contentable = manifest.contentable
  if (!contentable) return urls

  if (contentable.type === "Playlist") {
    const playlist = contentable as ManifestPlaylist
    for (const ad of playlist.playlist_ads) {
      addAdImages(ad, urls)
    }
  }

  return urls
}

function addAdImages(ad: ManifestPlaylistAd, urls: string[]): void {
  for (const img of ad.images) {
    if (img.url) urls.push(img.url)
  }

  if (ad.adable.type === "Ads::ListingAd") {
    for (const photo of ad.adable.listing.photos) {
      if (photo.url) urls.push(photo.url)
    }
    if (ad.adable.agent?.photos[0]?.url) {
      urls.push(ad.adable.agent.photos[0].url)
    }
  }
}
