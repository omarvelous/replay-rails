import { AdCanvas } from "../AdCanvas"
import { ListingAd } from "../ListingAd"
import { AgentAd } from "../AgentAd"
import { BrandAd } from "../BrandAd"
import { CollectionAd } from "../CollectionAd"
import type { ManifestPlaylistAd } from "../../../types"

interface AdRendererProps {
  ad: ManifestPlaylistAd
}

export function AdRenderer({ ad }: AdRendererProps) {
  return (
    <AdCanvas theme={ad.theme}>
      <AdContent ad={ad} />
    </AdCanvas>
  )
}

function AdContent({ ad }: AdRendererProps) {
  switch (ad.adable.type) {
    case "Ads::ListingAd":
      return <ListingAd ad={ad} />
    case "Ads::AgentAd":
      return <AgentAd ad={ad} />
    case "Ads::BrandAd":
      return <BrandAd ad={ad} />
    case "Ads::CollectionAd":
      return <CollectionAd ad={ad} />
  }
}
