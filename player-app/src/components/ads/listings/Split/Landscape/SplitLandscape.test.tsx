import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { SplitLandscape } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("SplitLandscape", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<SplitLandscape ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
