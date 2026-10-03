import type { ReactNode } from "react"

interface GridLayoutProps {
  children: ReactNode
}

// Full-area flex column — used for CollectionAd grid content
export function GridLayout({ children }: GridLayoutProps) {
  return (
    <div
      className="w-full h-full flex flex-col"
      style={{ background: "var(--ad-bg)", color: "var(--ad-text)", padding: "var(--s-pad-lg)" }}
    >
      {children}
    </div>
  )
}
