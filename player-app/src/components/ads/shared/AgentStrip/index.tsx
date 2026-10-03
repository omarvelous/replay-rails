import type { ManifestAgent } from "../../../../types"

interface AgentStripProps {
  agent: ManifestAgent
}

export function AgentStrip({ agent }: AgentStripProps) {
  return (
    <div className="flex items-center" style={{ gap: "var(--s-gap)", marginTop: "var(--s-gap)" }}>
      <div
        className="rounded-full flex-none overflow-hidden grid place-items-center bg-white/10"
        style={{ width: "var(--s-3xl)", height: "var(--s-3xl)" }}
      >
        {agent.photos[0] ? (
          <img src={agent.photos[0].url} alt={agent.name} className="w-full h-full object-cover" />
        ) : (
          <span className="font-bold" style={{ fontSize: "var(--s-base)", color: "var(--ad-text)" }}>
            {agent.name.slice(0, 2).toUpperCase()}
          </span>
        )}
      </div>
      <div className="flex items-center" style={{ gap: "var(--s-gap)", fontSize: "var(--s-xl)", color: "var(--ad-text-muted)" }}>
        <span className="font-semibold" style={{ color: "var(--ad-text)" }}>{agent.name}</span>
        {agent.phone && (
          <>
            <span>·</span>
            <span>{agent.phone}</span>
          </>
        )}
      </div>
    </div>
  )
}
