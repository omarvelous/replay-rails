import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { Badge } from "."

describe("Badge", () => {
  it("renders the label", () => {
    render(<Badge badge="just_listed" label="Just Listed" />)
    expect(screen.getByText("Just Listed")).toBeInTheDocument()
  })

  it("returns null when label is empty", () => {
    const { container } = render(<Badge badge="just_listed" label="" />)
    expect(container.innerHTML).toBe("")
  })
})
