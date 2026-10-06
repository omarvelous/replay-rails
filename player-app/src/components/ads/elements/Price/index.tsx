interface PriceProps {
  price: number
  originalPrice?: number | null
  soldPrice?: number | null
  badge?: string
}

const fmt = (n: number) =>
  new Intl.NumberFormat("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 }).format(n)

export function Price({ price, originalPrice, soldPrice, badge }: PriceProps) {
  const priceStyle: React.CSSProperties = {
    fontSize: "var(--t-price)",
    fontWeight: 600,
    lineHeight: 1,
    letterSpacing: "-0.035em",
    color: "var(--ad-text)",
  }

  // Just sold — show sold price as hero, listed price as faint
  if (badge === "just_sold" && soldPrice) {
    return (
      <div>
        <div style={priceStyle}>{fmt(soldPrice)}</div>
        <div style={{ fontSize: "var(--t-sub)", marginTop: "var(--gap-sm)", color: "var(--ad-text-faint)" }}>
          Listed at {fmt(price)}
        </div>
      </div>
    )
  }

  // Price reduction — current price + strikethrough original
  if (originalPrice) {
    return (
      <div className="flex items-baseline" style={{ gap: "var(--gap)" }}>
        <span style={priceStyle}>{fmt(price)}</span>
        <span style={{ fontSize: "var(--t-address)", textDecoration: "line-through", color: "var(--ad-text-faint)" }}>
          {fmt(originalPrice)}
        </span>
      </div>
    )
  }

  // Standard
  return <div style={priceStyle}>{fmt(price)}</div>
}
