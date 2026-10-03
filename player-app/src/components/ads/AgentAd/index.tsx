import { HeroLayout } from "../layouts/HeroLayout"
import { SplitLayout } from "../layouts/SplitLayout"
import { MinimalLayout } from "../layouts/MinimalLayout"
import { StatGridLayout } from "../layouts/StatGridLayout"
import type { ManifestPlaylistAd, ManifestAgentAd } from "../../../types"

interface AgentAdProps {
  ad: ManifestPlaylistAd
}

export function AgentAd({ ad }: AgentAdProps) {
  const agentAd = ad.adable as ManifestAgentAd
  const agent = agentAd.agent
  const imageUrl = ad.images[0]?.url

  const content = (
    <div className="flex items-center" style={{ gap: "var(--s-pad)" }}>
      <div
        className="rounded-full flex-none overflow-hidden grid place-items-center"
        style={{ width: "var(--s-avatar)", height: "var(--s-avatar)", background: "var(--ad-surface)", flexShrink: 0 }}
      >
        {agent.photos[0] ? (
          <img src={agent.photos[0].url} alt={agent.name} className="w-full h-full object-cover" />
        ) : (
          <span className="font-bold" style={{ fontSize: "var(--s-2xl)", color: "var(--ad-text)" }}>
            {agent.name.split(" ").map(w => w[0]).join("").slice(0, 2).toUpperCase()}
          </span>
        )}
      </div>

      <div>
        <div className="font-bold tracking-widest uppercase" style={{ fontSize: "var(--s-xl)", color: "var(--ad-accent)" }}>
          Your Agent
        </div>
        <div className="font-extrabold tracking-tight" style={{ fontSize: "var(--s-4xl)" }}>
          {agent.name}
        </div>
        {ad.body && (
          <div style={{ fontSize: "var(--s-2xl)", marginTop: "var(--s-xs)", color: "var(--ad-text-muted)" }}>
            {ad.body}
          </div>
        )}
        <div className="flex" style={{ gap: "var(--s-pad)", marginTop: "var(--s-gap)" }}>
          {agent.phone && (
            <div className="flex items-center" style={{ gap: "var(--s-xs)", fontSize: "var(--s-2xl)", color: "var(--ad-text-muted)" }}>
              <svg viewBox="0 0 20 20" fill="currentColor" style={{ width: "var(--s-2xl)", height: "var(--s-2xl)", color: "var(--ad-accent)", flexShrink: 0 }}>
                <path d="M2 3.5A1.5 1.5 0 013.5 2h1.148a1.5 1.5 0 011.465 1.175l.716 3.223a1.5 1.5 0 01-1.052 1.767l-.933.267c-.41.117-.643.555-.48.95a11.542 11.542 0 006.254 6.254c.395.163.833-.07.95-.48l.267-.933a1.5 1.5 0 011.767-1.052l3.223.716A1.5 1.5 0 0118 15.352V16.5a1.5 1.5 0 01-1.5 1.5H15c-1.149 0-2.263-.15-3.326-.43A13.022 13.022 0 012.43 8.326 13.019 13.019 0 012 5V3.5z" />
              </svg>
              {agent.phone}
            </div>
          )}
          {agent.email && (
            <div className="flex items-center" style={{ gap: "var(--s-xs)", fontSize: "var(--s-2xl)", color: "var(--ad-text-muted)" }}>
              <svg viewBox="0 0 20 20" fill="currentColor" style={{ width: "var(--s-2xl)", height: "var(--s-2xl)", color: "var(--ad-accent)", flexShrink: 0 }}>
                <path d="M3 4a2 2 0 00-2 2v1.161l8.441 4.221a1.25 1.25 0 001.118 0L19 7.162V6a2 2 0 00-2-2H3z" />
                <path d="M19 8.839l-7.77 3.885a2.75 2.75 0 01-2.46 0L1 8.839V14a2 2 0 002 2h14a2 2 0 002-2V8.839z" />
              </svg>
              {agent.email}
            </div>
          )}
        </div>
      </div>
    </div>
  )

  switch (ad.layout) {
    case "split":
      return <SplitLayout imageUrl={imageUrl}>{content}</SplitLayout>
    case "minimal":
      return <MinimalLayout>{content}</MinimalLayout>
    case "stat_grid":
      return <StatGridLayout>{content}</StatGridLayout>
    default: // hero
      return <HeroLayout imageUrl={imageUrl}>{content}</HeroLayout>
  }
}
