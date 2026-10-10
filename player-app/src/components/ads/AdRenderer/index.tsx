import { AdCanvas } from "../AdCanvas"
import type { Aspect } from "../AdCanvas"
import { useAspect } from "../../../utils/useAspect"
import { OverlayLandscape } from "../listings/Overlay/Landscape"
import { OverlayPortrait } from "../listings/Overlay/Portrait"
import { SplitLandscape } from "../listings/Split/Landscape"
import { SplitPortrait } from "../listings/Split/Portrait"
import { BandLandscape } from "../listings/Band/Landscape"
import { BandPortrait } from "../listings/Band/Portrait"
import { CardLandscape } from "../listings/Card/Landscape"
import { CardPortrait } from "../listings/Card/Portrait"
import { TypePhotoLandscape } from "../listings/TypePhoto/Landscape"
import { TypePhotoPortrait } from "../listings/TypePhoto/Portrait"
import { StatGridLandscape } from "../listings/StatGrid/Landscape"
import { StatGridPortrait } from "../listings/StatGrid/Portrait"
import { MosaicLandscape } from "../listings/Mosaic/Landscape"
import { MosaicPortrait } from "../listings/Mosaic/Portrait"
import { DiptychLandscape } from "../listings/Diptych/Landscape"
import { DiptychPortrait } from "../listings/Diptych/Portrait"
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
const LISTING_COMPOSITIONS: Record<
  string,
  Record<Aspect, React.ComponentType<{ ad: ManifestPlaylistAd; listingAd: ManifestListingAd }>>
> = {
  overlay: { landscape: OverlayLandscape, portrait: OverlayPortrait },
  split: { landscape: SplitLandscape, portrait: SplitPortrait },
  band: { landscape: BandLandscape, portrait: BandPortrait },
  card: { landscape: CardLandscape, portrait: CardPortrait },
  type_photo: { landscape: TypePhotoLandscape, portrait: TypePhotoPortrait },
  minimal: { landscape: TypePhotoLandscape, portrait: TypePhotoPortrait }, // alias for old records
  stat_grid: { landscape: StatGridLandscape, portrait: StatGridPortrait },
  mosaic: { landscape: MosaicLandscape, portrait: MosaicPortrait },
  diptych: { landscape: DiptychLandscape, portrait: DiptychPortrait },
}

function AdContent({ ad, aspect }: { ad: ManifestPlaylistAd; aspect: Aspect }) {
  if (ad.adable.type !== "Ads::ListingAd") return null

  const comps = LISTING_COMPOSITIONS[ad.layout]
  const Comp = comps?.[aspect]
  if (!Comp) return null

  return <Comp ad={ad} listingAd={ad.adable as ManifestListingAd} />
}
