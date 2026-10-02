import { useQuery } from "@tanstack/react-query"
import { api } from "../api/client"

export interface ManifestResponse {
  deploy: string
  screen_content: { pid: string; updated_at: number } | null
  contentable: {
    type: string
    pid: string
    [key: string]: unknown
  } | null
}

export function useManifestQuery(enabled: boolean) {
  return useQuery({
    queryKey: ["manifest"],
    queryFn: () => api<ManifestResponse>("/api/v1/player/manifest"),
    enabled,
    staleTime: Infinity,
    refetchOnWindowFocus: false,
  })
}
