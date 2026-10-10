interface StatBlockProps {
  beds?: number | null
  baths?: number | null
  sqft?: number | null
  yearBuilt?: number | null
}

export function StatBlock({ beds, baths, sqft, yearBuilt }: StatBlockProps) {
  const stats = [
    beds != null && { value: beds, label: "Bedrooms" },
    baths != null && { value: baths, label: "Bathrooms" },
    sqft != null && { value: sqft.toLocaleString(), label: "Sq Ft" },
    yearBuilt != null && { value: yearBuilt, label: "Year Built" },
  ].filter(Boolean) as { value: string | number; label: string }[]

  if (stats.length === 0) return null

  return (
    <div
      style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: "var(--gap-sm)",
        marginTop: "var(--gap)",
      }}
    >
      {stats.map((stat) => (
        <div
          key={stat.label}
          style={{
            padding: "var(--gap)",
            border: "1px solid var(--ad-text-faint)",
            borderRadius: "0.3cqw",
            borderColor: "rgba(255,255,255,0.12)",
          }}
        >
          <div style={{ fontSize: "var(--t-price)", fontWeight: 600, color: "var(--ad-text)", lineHeight: 1 }}>
            {stat.value}
          </div>
          <div
            style={{
              fontSize: "var(--t-spec-label, var(--t-spec))",
              fontWeight: 600,
              textTransform: "uppercase",
              letterSpacing: "0.14em",
              color: "var(--ad-text-faint)",
              marginTop: "0.3cqw",
            }}
          >
            {stat.label}
          </div>
        </div>
      ))}
    </div>
  )
}
