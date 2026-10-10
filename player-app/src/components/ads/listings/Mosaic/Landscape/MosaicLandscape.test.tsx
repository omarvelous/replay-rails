import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { MosaicLandscape } from "."
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

describe("MosaicLandscape", () => {
  it("renders without crashing", () => {
    const listing = mockListing({
      photos: [
        mockAttachment({ url: "/test/1.jpg" }),
        mockAttachment({ url: "/test/2.jpg" }),
        mockAttachment({ url: "/test/3.jpg" }),
      ],
    })
    const ad = mockPlaylistAd()
    const listingAd = mockListingAd({ listing })
    const { container } = render(<MosaicLandscape ad={ad} listingAd={listingAd} />)
    expect(container.firstChild).toBeTruthy()
  })
})
