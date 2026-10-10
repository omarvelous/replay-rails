interface AddressProps {
  street?: string | null
  city?: string | null
  state?: string | null
  neighborhood?: string | null
  address?: string // fallback when structured fields aren't populated
  style?: React.CSSProperties
}

export function Address({ street, city, state, neighborhood, address, style }: AddressProps) {
  const mainLine = street || address || ""
  const subLine = [neighborhood, city, state].filter(Boolean).join(", ") || null

  return (
    <div>
      <div
        style={{
          fontSize: "var(--t-address)",
          fontWeight: 600,
          lineHeight: 0.96,
          letterSpacing: "-0.035em",
          color: "var(--ad-text)",
          ...style,
        }}
      >
        {mainLine}
      </div>
      {subLine && (
        <div
          style={{
            fontSize: "var(--t-sub)",
            fontWeight: 500,
            color: "var(--ad-text-muted)",
            marginTop: "var(--gap-sm)",
          }}
        >
          {subLine}
        </div>
      )}
    </div>
  )
}
