import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { TypePhotoPortrait } from "."
import { mockPlaylistAd } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("TypePhotoPortrait", () => {
  it("renders without crashing", () => {
    const ad = mockPlaylistAd()
    const { container } = render(<TypePhotoPortrait ad={ad} listingAd={ad.adable as ManifestListingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
