import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { BandPortrait } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("BandPortrait", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<BandPortrait ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
