import type { ReactNode } from "react"

interface MinimalLayoutProps {
  children: ReactNode
}

// Covers both "minimal" and "profile" layout values — centered, no image
export function MinimalLayout({ children }: MinimalLayoutProps) {
  return (
    <div
      className="w-full h-full flex items-center justify-center text-center"
      style={{ background: "var(--ad-bg)", color: "var(--ad-text)", padding: "var(--s-pad-lg)" }}
    >
      <div>{children}</div>
    </div>
  )
}
