import { describe, it, expect, vi, beforeEach } from "vitest"
import { api, setToken, getToken, ApiError } from "./client"

describe("API client", () => {
  beforeEach(() => {
    setToken(null)
    vi.restoreAllMocks()
  })

  it("includes bearer token in Authorization header", async () => {
    setToken("test-token-123")

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ data: "ok" }),
      }),
    )

    await api("/api/v1/player")

    expect(fetch).toHaveBeenCalledWith(
      "/api/v1/player",
      expect.objectContaining({
        headers: expect.objectContaining({
          Authorization: "Bearer test-token-123",
        }),
      }),
    )
  })

  it("does not include Authorization when no token set", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ data: "ok" }),
      }),
    )

    await api("/api/v1/player")

    const headers = (fetch as ReturnType<typeof vi.fn>).mock.calls[0][1].headers
    expect(headers.Authorization).toBeUndefined()
  })

  it("throws ApiError on non-2xx response", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 401,
        text: () => Promise.resolve("Unauthorized"),
      }),
    )

    await expect(api("/api/v1/player")).rejects.toThrow(ApiError)
    await expect(api("/api/v1/player")).rejects.toThrow("API error: 401")
  })

  it("parses JSON response body", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: () => Promise.resolve({ data: { paired: true } }),
      }),
    )

    const result = await api("/api/v1/player")
    expect(result).toEqual({ data: { paired: true } })
  })

  describe("setToken / getToken", () => {
    it("stores and retrieves the token", () => {
      expect(getToken()).toBeNull()
      setToken("abc")
      expect(getToken()).toBe("abc")
    })

    it("clears the token with null", () => {
      setToken("abc")
      setToken(null)
      expect(getToken()).toBeNull()
    })
  })
})
