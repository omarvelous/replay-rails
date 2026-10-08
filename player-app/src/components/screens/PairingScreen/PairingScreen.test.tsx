import { describe, it, expect, vi } from "vitest"
import { render, screen } from "@testing-library/react"
import { PairingScreen } from "."

describe("PairingScreen", () => {
  const defaultProps = {
    code: "ABC123",
    expiresAt: new Date(Date.now() + 300_000), // 5 minutes from now
    onCodeExpired: vi.fn(),
  }

  it("displays the pairing code", () => {
    render(<PairingScreen {...defaultProps} />)
    expect(screen.getByText("ABC123")).toBeInTheDocument()
  })

  it("shows the pairing instructions", () => {
    render(<PairingScreen {...defaultProps} />)
    expect(screen.getByText("Pair this screen")).toBeInTheDocument()
    expect(screen.getByText(/Enter this code/)).toBeInTheDocument()
  })

  it("shows a countdown timer", () => {
    render(<PairingScreen {...defaultProps} />)
    expect(screen.getByText(/Expires in/)).toBeInTheDocument()
  })
})
