import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { Specs } from "."

describe("Specs", () => {
  it("renders beds, baths, sqft", () => {
    render(<Specs beds={3} baths={2} sqft={2200} />)
    expect(screen.getByText("3")).toBeInTheDocument()
    expect(screen.getByText("2")).toBeInTheDocument()
    expect(screen.getByText("2,200")).toBeInTheDocument()
  })

  it("returns null when all values are null", () => {
    const { container } = render(<Specs />)
    expect(container.innerHTML).toBe("")
  })
})
