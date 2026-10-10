import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { QrCode } from "."

describe("QrCode", () => {
  it("renders without crashing", () => {
    const { container } = render(<QrCode />)
    expect(container.firstChild).toBeTruthy()
  })
})
