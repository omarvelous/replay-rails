import type { ReactNode } from "react"

// Theme palettes — from listing-ads-visual-spec.md
const THEME_VARS: Record<string, Record<string, string>> = {
  dark: {
    "--ad-bg":         "#0B0D12",
    "--ad-text":       "#FFFFFF",
    "--ad-text-muted": "rgba(255,255,255,0.72)",
    "--ad-text-faint": "rgba(255,255,255,0.52)",
    "--ad-accent":     "#5B9BFF",
    "--ad-surface":    "#161A22",
    "--scrim":         "linear-gradient(to top, #0B0D12 0%, rgba(11,13,18,0.85) 30%, transparent 55%)",
  },
  light: {
    "--ad-bg":         "#F7F8FA",
    "--ad-text":       "#0B0D12",
    "--ad-text-muted": "#5B6470",
    "--ad-text-faint": "#6B7380",
    "--ad-accent":     "#2F6BFF",
    "--ad-surface":    "#FFFFFF",
    "--scrim":         "linear-gradient(to top, #F7F8FA 0%, rgba(247,248,250,0.85) 30%, transparent 55%)",
  },
  brand: {
    "--ad-bg":         "#14273F",
    "--ad-text":       "#FFFFFF",
    "--ad-text-muted": "rgba(255,255,255,0.72)",
    "--ad-text-faint": "rgba(255,255,255,0.52)",
    "--ad-accent":     "#7FA8D9",
    "--ad-surface":    "#1C3350",
    "--scrim":         "linear-gradient(to top, #14273F 0%, rgba(20,39,63,0.85) 30%, transparent 55%)",
  },
}

// Typography + spacing — dual scale by aspect (from visual spec)
const SIZING_LANDSCAPE: Record<string, string> = {
  "--t-price":      "5.6cqw",
  "--t-address":    "3.4cqw",
  "--t-sub":        "1.5cqw",
  "--t-spec":       "1.4cqw",
  "--t-spec-grid":  "2.4cqw",
  "--t-spec-label": "1.0cqw",
  "--t-badge":      "1.1cqw",
  "--t-agent-name": "1.2cqw",
  "--t-agent-detail":"1.0cqw",
  "--t-mark":       "1.3cqw",
  "--safe":         "3.2cqw",
  "--qr-size":      "6.5cqw",
  "--avatar":       "3.4cqw",
  "--gap":          "1.2cqw",
  "--gap-sm":       "0.6cqw",
}

const SIZING_PORTRAIT: Record<string, string> = {
  "--t-price":      "11cqw",
  "--t-address":    "7cqw",
  "--t-sub":        "3.4cqw",
  "--t-spec":       "3.2cqw",
  "--t-spec-grid":  "5cqw",
  "--t-spec-label": "2cqw",
  "--t-badge":      "2.4cqw",
  "--t-agent-name": "2.6cqw",
  "--t-agent-detail":"2.2cqw",
  "--t-mark":       "2.6cqw",
  "--safe":         "6cqw",
  "--qr-size":      "15cqw",
  "--avatar":       "7cqw",
  "--gap":          "2.4cqw",
  "--gap-sm":       "1.2cqw",
}

// Legacy --s-* vars for AgentAd, BrandAd, CollectionAd (unchanged components)
const SIZING_LEGACY: Record<string, string> = {
  "--s-xs":       "1cqw",
  "--s-sm":       "1.3cqw",
  "--s-base":     "1.8cqw",
  "--s-lg":       "2.2cqw",
  "--s-xl":       "2.6cqw",
  "--s-2xl":      "3.2cqw",
  "--s-3xl":      "4cqw",
  "--s-4xl":      "5cqw",
  "--s-hero":     "7cqw",
  "--s-pad":      "5cqw",
  "--s-pad-lg":   "7cqw",
  "--s-gap":      "1.5cqw",
  "--s-qr":       "8cqw",
  "--s-avatar":   "15cqw",
  "--s-badge-px": "1.2cqw",
  "--s-badge-py": "0.4cqw",
}

export type Aspect = "landscape" | "portrait"

interface AdCanvasProps {
  theme?: string
  aspect?: Aspect
  children: ReactNode
}

export function AdCanvas({ theme = "dark", aspect = "landscape", children }: AdCanvasProps) {
  const themeVars = THEME_VARS[theme] ?? THEME_VARS.dark
  const sizingVars = aspect === "portrait" ? SIZING_PORTRAIT : SIZING_LANDSCAPE
  const style = { ...themeVars, ...sizingVars, ...SIZING_LEGACY, containerType: "inline-size" } as React.CSSProperties

  return (
    <div className="relative w-full h-full overflow-hidden" style={style}>
      {children}
    </div>
  )
}
