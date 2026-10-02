import { useQuery } from "@tanstack/react-query"
import { api, ApiError } from "../api/client"
import type { ApiResponse, PlayerStatus } from "../types"

export function usePlayerQuery(enabled: boolean) {
  return useQuery({
    queryKey: ["player"],
    queryFn: async () => {
      const res = await api<ApiResponse<PlayerStatus>>("/api/v1/player")
      return res.data
    },
    enabled,
    retry: (failureCount, error) => {
      if (error instanceof ApiError && error.status === 401) return false
      return failureCount < 3
    },
    refetchOnWindowFocus: false,
  })
}
