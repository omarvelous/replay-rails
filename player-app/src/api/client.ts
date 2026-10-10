let authToken: string | null = null

export function setToken(token: string | null) {
  authToken = token
}

export function getToken(): string | null {
  return authToken
}

export class ApiError extends Error {
  status: number

  constructor(status: number, message: string) {
    super(message)
    this.name = "ApiError"
    this.status = status
  }
}

export async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  }

  if (authToken) {
    headers["Authorization"] = `Bearer ${authToken}`
  }

  const res = await fetch(path, { ...options, headers })

  if (!res.ok) {
    throw new ApiError(res.status, `API error: ${res.status}`)
  }

  return res.json()
}
