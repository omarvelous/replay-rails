interface BadgeProps {
  badge: string
  label: string
}

export function Badge({ badge, label }: BadgeProps) {
  if (!label) return null

  const style: React.CSSProperties = {
    fontSize: "var(--t-badge)",
    padding: "0.6cqw 1.0cqw",
    borderRadius: "0.3cqw",
    letterSpacing: "0.14em",
    background: BADGE_COLORS[badge] ?? "var(--ad-accent)",
    color: BADGE_TEXT[badge] ?? "var(--ad-bg)",
  }

  return (
    <span
      className="inline-flex items-center font-semibold uppercase"
      style={style}
    >
      {label}
    </span>
  )
}

// Per visual spec: most badges use --ad-accent, sold/coming soon use teal
const BADGE_COLORS: Record<string, string> = {
  just_sold:   "#0FB5A6",
  coming_soon: "#0FB5A6",
}

const BADGE_TEXT: Record<string, string> = {
  just_sold:   "#0B0D12",
  coming_soon: "#0B0D12",
}
