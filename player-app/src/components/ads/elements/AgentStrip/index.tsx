import type { ManifestAgent } from "../../../../types"

interface AgentStripProps {
  agent: ManifestAgent
  pill?: boolean
}

export function AgentStrip({ agent, pill }: AgentStripProps) {
  const initials = agent.name
    .split(" ")
    .map((w) => w[0])
    .join("")
    .slice(0, 2)
    .toUpperCase()

  const wrapStyle: React.CSSProperties = pill
    ? { background: "var(--ad-surface)", padding: "0.5cqw 1.0cqw", borderRadius: "2cqw" }
    : {}

  return (
    <div className="flex items-center" style={{ gap: "0.8cqw", ...wrapStyle }}>
      <div
        className="rounded-full flex-none overflow-hidden grid place-items-center"
        style={{ width: "var(--avatar)", height: "var(--avatar)", background: "var(--ad-surface)" }}
      >
        {agent.photos[0] ? (
          <img src={agent.photos[0].url} alt={agent.name} className="w-full h-full object-cover" />
        ) : (
          <span style={{ fontSize: "var(--t-agent-detail)", fontWeight: 600, color: "var(--ad-text-faint)" }}>
            {initials}
          </span>
        )}
      </div>
      <div>
        <div style={{ fontSize: "var(--t-agent-name)", fontWeight: 600, color: "var(--ad-text)" }}>{agent.name}</div>
        {agent.phone && (
          <div style={{ fontSize: "var(--t-agent-detail)", fontWeight: 500, color: "var(--ad-text-muted)" }}>
            {agent.phone}
          </div>
        )}
      </div>
    </div>
  )
}
