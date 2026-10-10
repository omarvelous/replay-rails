import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { OverlayPortrait } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("OverlayPortrait", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<OverlayPortrait ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
