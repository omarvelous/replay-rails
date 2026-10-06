import { AdCanvas } from "../AdCanvas"
import type { Aspect } from "../AdCanvas"
import { useAspect } from "../../../utils/useAspect"
import { OverlayLandscape } from "../Overlay/Landscape"
import { OverlayPortrait } from "../Overlay/Portrait"
import { SplitLandscape } from "../Split/Landscape"
import { SplitPortrait } from "../Split/Portrait"
import { AgentAd } from "../AgentAd"
import { BrandAd } from "../BrandAd"
import { CollectionAd } from "../CollectionAd"
import type { ManifestPlaylistAd, ManifestListingAd } from "../../../types"

interface AdRendererProps {
  ad: ManifestPlaylistAd
}

export function AdRenderer({ ad }: AdRendererProps) {
  const aspect = useAspect()

  return (
    <AdCanvas theme={ad.theme} aspect={aspect}>
      <AdContent ad={ad} aspect={aspect} />
    </AdCanvas>
  )
}

// Listing ad compositions: layout × aspect
const LISTING_COMPOSITIONS: Record<string, Record<Aspect, React.ComponentType<{ ad: ManifestPlaylistAd; listingAd: ManifestListingAd }>>> = {
  overlay:   { landscape: OverlayLandscape,  portrait: OverlayPortrait },
  split:     { landscape: SplitLandscape,    portrait: SplitPortrait },
  hero:      { landscape: OverlayLandscape,  portrait: OverlayPortrait }, // alias for old records
}

function AdContent({ ad, aspect }: { ad: ManifestPlaylistAd; aspect: Aspect }) {
  // Listing ads — dispatch by layout × aspect
  if (ad.adable.type === "Ads::ListingAd") {
    const comps = LISTING_COMPOSITIONS[ad.layout]
    const Comp = comps?.[aspect]
    if (Comp) return <Comp ad={ad} listingAd={ad.adable as ManifestListingAd} />
  }

  // Other ad types — unchanged
  switch (ad.adable.type) {
    case "Ads::AgentAd":
      return <AgentAd ad={ad} />
    case "Ads::BrandAd":
      return <BrandAd ad={ad} />
    case "Ads::CollectionAd":
      return <CollectionAd ad={ad} />
  }
}
