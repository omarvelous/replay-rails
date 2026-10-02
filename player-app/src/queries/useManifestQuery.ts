import { useQuery } from "@tanstack/react-query"
import { api } from "../api/client"
import type { ManifestResponse } from "../types"

export function useManifestQuery(enabled: boolean) {
  return useQuery({
    queryKey: ["manifest"],
    queryFn: () => api<ManifestResponse>("/api/v1/player/manifest"),
    enabled,
    staleTime: Infinity,
    refetchOnWindowFocus: false,
  })
}
