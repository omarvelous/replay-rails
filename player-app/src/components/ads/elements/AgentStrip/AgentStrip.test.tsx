import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { AgentStrip } from "."
import { mockAgent } from "../../../../__mocks__/manifest"

describe("AgentStrip", () => {
  it("renders agent name", () => {
    render(<AgentStrip agent={mockAgent()} />)
    expect(screen.getByText("Jane Archer")).toBeInTheDocument()
  })

  it("renders initials when no photo", () => {
    render(<AgentStrip agent={mockAgent({ photos: [] })} />)
    expect(screen.getByText("JA")).toBeInTheDocument()
  })
})
