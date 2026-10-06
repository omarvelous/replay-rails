interface AddressProps {
  address: string
  neighborhood?: string
  style?: React.CSSProperties
}

export function Address({ address, neighborhood, style }: AddressProps) {
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
        {address}
      </div>
      {neighborhood && (
        <div style={{ fontSize: "var(--t-sub)", fontWeight: 500, color: "var(--ad-text-muted)", marginTop: "var(--gap-sm)" }}>
          {neighborhood}
        </div>
      )}
    </div>
  )
}
