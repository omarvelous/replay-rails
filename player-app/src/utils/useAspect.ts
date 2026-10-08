import type { Aspect } from "../components/ads/AdCanvas"

export function useAspect(): Aspect {
  return window.innerWidth >= window.innerHeight ? "landscape" : "portrait"
}
