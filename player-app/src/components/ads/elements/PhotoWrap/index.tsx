interface PhotoWrapProps {
  src?: string
  scrim?: boolean
}

export function PhotoWrap({ src, scrim }: PhotoWrapProps) {
  return (
    <div className="absolute inset-0">
      {src ? (
        <img src={src} alt="" className="absolute inset-0 w-full h-full object-cover" />
      ) : (
        <div className="absolute inset-0" style={{ background: "var(--ad-surface)" }} />
      )}
      {scrim && (
        <div className="absolute inset-0" style={{ background: "var(--scrim)" }} />
      )}
    </div>
  )
}
