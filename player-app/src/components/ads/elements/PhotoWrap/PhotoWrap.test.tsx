import { describe, it, expect } from "vitest"
import { render } from "@testing-library/react"
import { PhotoWrap } from "."

describe("PhotoWrap", () => {
  it("renders image when src provided", () => {
    const { container } = render(<PhotoWrap src="/test.jpg" />)
    expect(container.querySelector("img")).toBeTruthy()
  })

  it("renders fallback when no src", () => {
    const { container } = render(<PhotoWrap />)
    expect(container.querySelector("img")).toBeFalsy()
  })

  it("renders scrim when enabled", () => {
    const { container } = render(<PhotoWrap src="/test.jpg" scrim />)
    expect(container.querySelectorAll("div").length).toBeGreaterThan(1)
  })
})
