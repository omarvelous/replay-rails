import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { Slideshow } from "./Slideshow"
import {
  mockManifestResponse,
  mockPlaylist,
  mockPlaylistAd,
  mockListingAd,
  mockAgentAd,
  mockBrandAd,
  mockAttachment,
} from "../../../__mocks__/manifest"

describe("Slideshow", () => {
  it("renders the first ad headline", () => {
    const manifest = mockManifestResponse()
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("Just Listed")).toBeInTheDocument()
  })

  it("renders listing ad badge", () => {
    const manifest = mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({ adable: mockListingAd({ badge_label: "Open House" }) })],
      }),
    })
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("Open House")).toBeInTheDocument()
  })

  it("renders listing ad price", () => {
    const manifest = mockManifestResponse()
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("$2,500,000")).toBeInTheDocument()
  })

  it("renders listing ad address", () => {
    const manifest = mockManifestResponse()
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("350 Fifth Ave, New York, NY 10118")).toBeInTheDocument()
  })

  it("renders listing ad specs", () => {
    const manifest = mockManifestResponse()
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("3 bd · 2 ba · 2,200 sqft")).toBeInTheDocument()
  })

  it("renders agent strip on listing ad", () => {
    const manifest = mockManifestResponse()
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("Jane Archer")).toBeInTheDocument()
  })

  it("renders agent ad with agent name", () => {
    const manifest = mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Your Agent",
          adable: mockAgentAd(),
        })],
      }),
    })
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("Jane Archer")).toBeInTheDocument()
  })

  it("renders brand ad with headline only", () => {
    const manifest = mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Your Window, Working 24/7",
          body: "Digital signage for real estate.",
          adable: mockBrandAd(),
        })],
      }),
    })
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("Your Window, Working 24/7")).toBeInTheDocument()
    expect(screen.getByText("Digital signage for real estate.")).toBeInTheDocument()
  })

  it("renders ad image", () => {
    const manifest = mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Hero Ad",
          images: [mockAttachment({ url: "/test/hero.jpg" })],
          adable: mockBrandAd(),
        })],
      }),
    })
    render(<Slideshow manifest={manifest} />)
    const img = screen.getByAltText("Hero Ad")
    expect(img).toHaveAttribute("src", "/test/hero.jpg")
  })

  it("renders without background image when none attached", () => {
    const manifest = mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "No Image",
          images: [],
          adable: mockBrandAd(),
        })],
      }),
    })
    render(<Slideshow manifest={manifest} />)
    expect(screen.queryByAltText("No Image")).not.toBeInTheDocument()
  })

  it("renders price reduction with original price", () => {
    const manifest = mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Price Reduced",
          adable: mockListingAd({
            badge: "price_reduction",
            badge_label: "Price Reduced",
            original_price: 3000000,
          }),
        })],
      }),
    })
    render(<Slideshow manifest={manifest} />)
    expect(screen.getByText("$3,000,000")).toBeInTheDocument()
  })
})
