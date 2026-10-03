import type { ReactNode } from "react"

// Theme variable sets — matches Rails ad_theme_style helper
const THEME_VARS: Record<string, Record<string, string>> = {
  dark: {
    "--ad-bg":         "#0b0d12",
    "--ad-text":       "#ffffff",
    "--ad-text-muted": "rgba(255,255,255,0.6)",
    "--ad-text-faint": "rgba(255,255,255,0.45)",
    "--ad-accent":     "#5b8eff",
    "--ad-surface":    "rgba(255,255,255,0.1)",
  },
  light: {
    "--ad-bg":         "#f9fafb",
    "--ad-text":       "#111827",
    "--ad-text-muted": "#4b5563",
    "--ad-text-faint": "#6b7280",
    "--ad-accent":     "#2f6bff",
    "--ad-surface":    "#ffffff",
  },
}

// Container-query sizing scale — all relative to the ad canvas width (cqw)
const SIZING_VARS: Record<string, string> = {
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

interface AdCanvasProps {
  theme?: string
  children: ReactNode
}

export function AdCanvas({ theme = "dark", children }: AdCanvasProps) {
  const themeVars = THEME_VARS[theme] ?? THEME_VARS.dark
  const style = { ...themeVars, ...SIZING_VARS, containerType: "inline-size" } as React.CSSProperties

  return (
    <div className="relative w-full h-full overflow-hidden" style={style}>
      {children}
    </div>
  )
}
