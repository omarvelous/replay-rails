const BADGE_COLORS: Record<string, string> = {
  just_listed:     "bg-green-500",
  open_house:      "bg-amber-500",
  just_sold:       "bg-red-500",
  price_reduction: "bg-orange-500",
  coming_soon:     "bg-purple-500",
}

interface BadgeProps {
  badge: string
  label: string
}

export function Badge({ badge, label }: BadgeProps) {
  if (!label) return null
  const color = BADGE_COLORS[badge] ?? "bg-gray-500"

  return (
    <span
      className={`inline-flex items-center rounded-full ${color} font-bold text-white tracking-wider uppercase`}
      style={{ fontSize: "var(--s-2xl)", padding: "var(--s-badge-py) var(--s-badge-px)" }}
    >
      {label}
    </span>
  )
}
