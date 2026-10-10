import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { Address } from "."

describe("Address", () => {
  it("renders street from structured fields", () => {
    render(<Address street="350 Fifth Ave" city="New York" state="NY" />)
    expect(screen.getByText("350 Fifth Ave")).toBeInTheDocument()
    expect(screen.getByText(/New York/)).toBeInTheDocument()
  })

  it("falls back to address string", () => {
    render(<Address address="350 Fifth Ave, New York, NY" />)
    expect(screen.getByText("350 Fifth Ave, New York, NY")).toBeInTheDocument()
  })

  it("renders neighborhood when provided", () => {
    render(<Address street="350 Fifth Ave" city="New York" state="NY" neighborhood="Midtown" />)
    expect(screen.getByText(/Midtown/)).toBeInTheDocument()
  })
})
