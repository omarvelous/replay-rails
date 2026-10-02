import { useQuery, useQueryClient } from "@tanstack/react-query"
import { api } from "../api/client"
import type { ApiResponse, HeartbeatResponse } from "../types"

export function useHeartbeat(enabled: boolean, currentVersion: number | null) {
  const queryClient = useQueryClient()

  return useQuery({
    queryKey: ["heartbeat"],
    queryFn: async () => {
      const res = await api<ApiResponse<HeartbeatResponse>>("/api/v1/player/heartbeat", {
        method: "POST",
        body: JSON.stringify({
          screen_width: screen.width,
          screen_height: screen.height,
        }),
      })

      if (currentVersion && res.data.content_version && res.data.content_version !== currentVersion) {
        queryClient.invalidateQueries({ queryKey: ["manifest"] })
      }

      return res.data
    },
    enabled,
    refetchInterval: 30_000,
    refetchIntervalInBackground: true,
    refetchOnWindowFocus: false,
  })
}
