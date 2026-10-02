import { useQuery } from "@tanstack/react-query"
import { api } from "../api/client"
import type { ApiResponse, Manifest } from "../types"

export function useManifestQuery(enabled: boolean) {
  return useQuery({
    queryKey: ["manifest"],
    queryFn: async () => {
      const res = await api<ApiResponse<Manifest>>("/api/v1/player/manifest")
      return res.data
    },
    enabled,
    staleTime: Infinity,
    refetchOnWindowFocus: false,
  })
}
