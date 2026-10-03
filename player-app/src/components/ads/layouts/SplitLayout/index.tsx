import type { ReactNode } from "react"

interface SplitLayoutProps {
  imageUrl?: string
  children: ReactNode
}

export function SplitLayout({ imageUrl, children }: SplitLayoutProps) {
  return (
    <div className="w-full h-full flex" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      <div className="w-1/2 relative overflow-hidden flex-none">
        {imageUrl ? (
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
        ) : (
          <div className="w-full h-full" style={{ background: "var(--ad-surface)" }} />
        )}
      </div>
      <div className="w-1/2 flex flex-col justify-center" style={{ padding: "var(--s-pad-lg)" }}>
        {children}
      </div>
    </div>
  )
}
