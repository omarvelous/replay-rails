import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { IdleScreen } from "./IdleScreen"

describe("IdleScreen", () => {
  it("renders no content message", () => {
    render(<IdleScreen />)
    expect(screen.getByText("No content assigned")).toBeInTheDocument()
  })

  it("shows instructions", () => {
    render(<IdleScreen />)
    expect(screen.getByText(/Assign a playlist or experience/)).toBeInTheDocument()
  })
})
