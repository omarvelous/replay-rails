import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { BandLandscape } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("BandLandscape", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<BandLandscape ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
