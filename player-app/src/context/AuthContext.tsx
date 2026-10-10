import { createContext, useContext, useState, useCallback, useEffect, type ReactNode } from "react"
import { setToken as setApiToken } from "../api/client"
import type { RegistrationResponse } from "../types"

interface AuthState {
  token: string | null
  publicId: string | null
  isAuthenticated: boolean
  register: (data: RegistrationResponse) => void
  clear: () => void
}

const AuthContext = createContext<AuthState | null>(null)

export function AuthProvider({ children }: { children: ReactNode }) {
  const [token, setToken] = useState<string | null>(() => {
    const stored = localStorage.getItem("player_token")
    if (stored) setApiToken(stored)
    return stored
  })
  const [publicId, setPublicId] = useState<string | null>(() => localStorage.getItem("player_public_id"))

  useEffect(() => {
    setApiToken(token)
  }, [token])

  const register = useCallback((data: RegistrationResponse) => {
    localStorage.setItem("player_token", data.token)
    localStorage.setItem("player_public_id", data.public_id)
    setToken(data.token)
    setPublicId(data.public_id)
  }, [])

  const clear = useCallback(() => {
    localStorage.removeItem("player_token")
    localStorage.removeItem("player_public_id")
    setToken(null)
    setPublicId(null)
    setApiToken(null)
  }, [])

  return (
    <AuthContext.Provider
      value={{
        token,
        publicId,
        isAuthenticated: token !== null,
        register,
        clear,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) throw new Error("useAuth must be used within AuthProvider")
  return context
}
