import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { ErrorScreen } from "."

describe("ErrorScreen", () => {
  it("renders the error message", () => {
    render(<ErrorScreen error="Network connection lost" />)
    expect(screen.getByText("Network connection lost")).toBeInTheDocument()
  })

  it("shows retry message", () => {
    render(<ErrorScreen error="Failed" />)
    expect(screen.getByText(/Retrying automatically/)).toBeInTheDocument()
  })
})
