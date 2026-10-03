import { MinimalLayout } from "../layouts/MinimalLayout"
import type { ManifestPlaylistAd } from "../../../types"

interface BrandAdProps {
  ad: ManifestPlaylistAd
}

// BrandAd uses MinimalLayout only for now — hero/split deferred until
// image support is added to the BrandAd manifest response.
export function BrandAd({ ad }: BrandAdProps) {
  return (
    <MinimalLayout>
      <div className="font-extrabold tracking-tight leading-tight" style={{ fontSize: "var(--s-hero)" }}>
        {ad.headline}
      </div>
      {ad.body && (
        <div style={{ fontSize: "var(--s-2xl)", marginTop: "var(--s-gap)", color: "var(--ad-text-muted)" }}>
          {ad.body}
        </div>
      )}
    </MinimalLayout>
  )
}
