import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { StatBlock } from "."

describe("StatBlock", () => {
  it("renders stat values", () => {
    render(<StatBlock beds={4} baths={3} sqft={3240} />)
    expect(screen.getByText("4")).toBeInTheDocument()
    expect(screen.getByText("3")).toBeInTheDocument()
    expect(screen.getByText("3,240")).toBeInTheDocument()
  })

  it("returns null when all values are null", () => {
    const { container } = render(<StatBlock />)
    expect(container.innerHTML).toBe("")
  })
})
