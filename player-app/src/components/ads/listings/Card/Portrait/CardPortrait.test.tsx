import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { CardPortrait } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("CardPortrait", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<CardPortrait ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
