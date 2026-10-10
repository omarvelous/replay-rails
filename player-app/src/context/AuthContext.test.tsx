import { describe, it, expect, beforeEach } from "vitest"
import { render, screen, act } from "@testing-library/react"
import { AuthProvider, useAuth } from "./AuthContext"
import { getToken } from "../api/client"

function TestConsumer() {
  const { token, publicId, isAuthenticated, register, clear } = useAuth()
  return (
    <div>
      <span data-testid="token">{token ?? "null"}</span>
      <span data-testid="publicId">{publicId ?? "null"}</span>
      <span data-testid="isAuthenticated">{String(isAuthenticated)}</span>
      <button onClick={() => register({ token: "tok-123", public_id: "pid-456", pairing_code: "ABC", expires_at: "" })}>
        Register
      </button>
      <button onClick={clear}>Clear</button>
    </div>
  )
}

describe("AuthContext", () => {
  beforeEach(() => {
    localStorage.clear()
  })

  it("returns isAuthenticated: false when no token", () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>,
    )
    expect(screen.getByTestId("isAuthenticated").textContent).toBe("false")
    expect(screen.getByTestId("token").textContent).toBe("null")
  })

  it("hydrates token from localStorage on mount", () => {
    localStorage.setItem("player_token", "stored-token")
    localStorage.setItem("player_public_id", "stored-pid")
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>,
    )
    expect(screen.getByTestId("token").textContent).toBe("stored-token")
    expect(screen.getByTestId("publicId").textContent).toBe("stored-pid")
    expect(screen.getByTestId("isAuthenticated").textContent).toBe("true")
  })

  it("sets API client token on mount", () => {
    localStorage.setItem("player_token", "api-token")
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>,
    )
    expect(getToken()).toBe("api-token")
  })

  it("register() stores token in state and localStorage", () => {
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>,
    )

    act(() => {
      screen.getByText("Register").click()
    })

    expect(screen.getByTestId("token").textContent).toBe("tok-123")
    expect(screen.getByTestId("publicId").textContent).toBe("pid-456")
    expect(localStorage.getItem("player_token")).toBe("tok-123")
    expect(localStorage.getItem("player_public_id")).toBe("pid-456")
  })

  it("clear() removes token from state and localStorage", () => {
    localStorage.setItem("player_token", "to-clear")
    localStorage.setItem("player_public_id", "to-clear-pid")
    render(
      <AuthProvider>
        <TestConsumer />
      </AuthProvider>,
    )

    act(() => {
      screen.getByText("Clear").click()
    })

    expect(screen.getByTestId("token").textContent).toBe("null")
    expect(screen.getByTestId("isAuthenticated").textContent).toBe("false")
    expect(localStorage.getItem("player_token")).toBeNull()
    expect(localStorage.getItem("player_public_id")).toBeNull()
  })
})
