import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { CardLandscape } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("CardLandscape", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<CardLandscape ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
