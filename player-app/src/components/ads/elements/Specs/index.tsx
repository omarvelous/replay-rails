interface SpecsProps {
  beds?: number | null
  baths?: number | null
  sqft?: number | null
}

export function Specs({ beds, baths, sqft }: SpecsProps) {
  const items = [
    beds != null && { value: beds, label: "bd" },
    baths != null && { value: baths, label: "ba" },
    sqft != null && { value: sqft.toLocaleString(), label: "sqft" },
  ].filter(Boolean) as { value: string | number; label: string }[]

  if (items.length === 0) return null

  return (
    <div
      className="flex items-center"
      style={{
        gap: "0.8cqw",
        fontSize: "var(--t-spec)",
        fontWeight: 600,
        color: "var(--ad-text)",
        marginTop: "var(--gap-sm)",
      }}
    >
      {items.map((item, i) => (
        <span key={item.label} className="flex items-center" style={{ gap: "0.8cqw" }}>
          {i > 0 && (
            <span style={{ width: "1px", height: "1.2cqw", background: "var(--ad-text-faint)", opacity: 0.3 }} />
          )}
          <span>{item.value}</span>
          <span style={{ fontWeight: 500, color: "var(--ad-text-faint)" }}>{item.label}</span>
        </span>
      ))}
    </div>
  )
}
