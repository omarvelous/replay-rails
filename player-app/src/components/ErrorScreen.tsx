interface ErrorScreenProps {
  error: string
}

export function ErrorScreen({ error }: ErrorScreenProps) {
  return (
    <div className="flex flex-col items-center justify-center h-dvh bg-black text-white gap-4">
      <p className="text-2xl text-white/30 font-semibold">Something went wrong</p>
      <p className="text-sm text-white/20">{error}</p>
      <p className="text-xs text-white/10">Retrying automatically...</p>
    </div>
  )
}
