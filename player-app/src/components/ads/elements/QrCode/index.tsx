export function QrCode() {
  return (
    <div
      className="grid place-items-center"
      style={{ width: "var(--qr-size)", height: "var(--qr-size)", background: "#fff", borderRadius: "6%", flexShrink: 0 }}
    >
      <div style={{ width: "72%", height: "72%", background: "#0B0D12", borderRadius: "2px" }} />
    </div>
  )
}
