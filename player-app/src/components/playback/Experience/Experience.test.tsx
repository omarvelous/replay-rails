import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { Experience } from "."
import {
  mockManifestResponse,
  mockExperience,
  mockListing,
  mockAgent,
  mockListingExperience,
} from "../../../__mocks__/manifest"

describe("Experience", () => {
  it("renders listing address", () => {
    const manifest = mockManifestResponse({ contentable: mockExperience() })
    render(<Experience manifest={manifest} />)
    expect(screen.getByText("350 Fifth Ave, New York, NY 10118")).toBeInTheDocument()
  })

  it("renders listing price", () => {
    const manifest = mockManifestResponse({ contentable: mockExperience() })
    render(<Experience manifest={manifest} />)
    expect(screen.getByText("$2,500,000")).toBeInTheDocument()
  })

  it("renders listing specs", () => {
    const manifest = mockManifestResponse({ contentable: mockExperience() })
    render(<Experience manifest={manifest} />)
    expect(screen.getByText("3 bed · 2 bath · 2,200 sqft")).toBeInTheDocument()
  })

  it("renders agent card when agent present", () => {
    const manifest = mockManifestResponse({ contentable: mockExperience() })
    render(<Experience manifest={manifest} />)
    expect(screen.getByText("Jane Archer")).toBeInTheDocument()
  })

  it("renders without agent when none assigned", () => {
    const manifest = mockManifestResponse({
      contentable: mockExperience({
        experienceable: mockListingExperience({ agent: undefined }),
      }),
    })
    render(<Experience manifest={manifest} />)
    expect(screen.queryByText("Jane Archer")).not.toBeInTheDocument()
    expect(screen.getByText("350 Fifth Ave, New York, NY 10118")).toBeInTheDocument()
  })

  it("renders listing photo", () => {
    const manifest = mockManifestResponse({ contentable: mockExperience() })
    render(<Experience manifest={manifest} />)
    const img = screen.getByAltText("350 Fifth Ave, New York, NY 10118")
    expect(img).toHaveAttribute("src", "/test/listing.jpg")
  })
})
