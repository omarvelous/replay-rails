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
            {agent.name.slice(0, 2).toUpperCase()}
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
            <div style={{ fontSize: "var(--s-2xl)", color: "var(--ad-text-muted)" }}>{agent.phone}</div>
          )}
          {agent.email && (
            <div style={{ fontSize: "var(--s-2xl)", color: "var(--ad-text-muted)" }}>{agent.email}</div>
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
