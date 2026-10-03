import type { ReactNode } from "react"

interface StatGridLayoutProps {
  children: ReactNode
}

// Vertically centered, left-aligned — used for agent ads with stat blocks
export function StatGridLayout({ children }: StatGridLayoutProps) {
  return (
    <div
      className="w-full h-full flex flex-col justify-center"
      style={{ background: "var(--ad-bg)", color: "var(--ad-text)", padding: "var(--s-pad-lg)" }}
    >
      {children}
    </div>
  )
}
