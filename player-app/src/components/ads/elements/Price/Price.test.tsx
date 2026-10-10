import { describe, it, expect } from "vitest"
import { render, screen } from "@testing-library/react"
import { Price } from "."

describe("Price", () => {
  it("renders formatted price", () => {
    render(<Price price={2500000} />)
    expect(screen.getByText("$2,500,000")).toBeInTheDocument()
  })

  it("renders price reduction with strikethrough", () => {
    render(<Price price={2500000} originalPrice={2800000} />)
    expect(screen.getByText("$2,500,000")).toBeInTheDocument()
    expect(screen.getByText("$2,800,000")).toBeInTheDocument()
  })

  it("renders just sold with listed price", () => {
    render(<Price price={2500000} soldPrice={2600000} badge="just_sold" />)
    expect(screen.getByText("$2,600,000")).toBeInTheDocument()
    expect(screen.getByText(/Listed at/)).toBeInTheDocument()
  })
})
