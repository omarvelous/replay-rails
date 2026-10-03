import type { ReactNode } from "react"

interface HeroLayoutProps {
  imageUrl?: string
  children: ReactNode
}

export function HeroLayout({ imageUrl, children }: HeroLayoutProps) {
  return (
    <div className="relative w-full h-full flex flex-col justify-end" style={{ background: "var(--ad-bg)", color: "var(--ad-text)" }}>
      {imageUrl && (
        <>
          <img src={imageUrl} alt="" className="absolute inset-0 w-full h-full object-cover" />
          <div className="absolute inset-0" style={{ background: "linear-gradient(to top, rgba(0,0,0,0.75) 0%, transparent 60%)" }} />
        </>
      )}
      <div className="relative" style={{ padding: "var(--s-pad)" }}>
        {children}
      </div>
    </div>
  )
}
