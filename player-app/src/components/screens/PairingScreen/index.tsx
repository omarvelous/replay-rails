import { useState, useEffect } from "react"

interface PairingScreenProps {
  code: string
  expiresAt: Date
  onCodeExpired: () => void
}

export function PairingScreen({ code, expiresAt, onCodeExpired }: PairingScreenProps) {
  const [secondsLeft, setSecondsLeft] = useState(() =>
    Math.max(0, Math.floor((expiresAt.getTime() - Date.now()) / 1000))
  )

  useEffect(() => {
    const interval = setInterval(() => {
      const remaining = Math.floor((expiresAt.getTime() - Date.now()) / 1000)
      if (remaining <= 0) {
        clearInterval(interval)
        onCodeExpired()
      } else {
        setSecondsLeft(remaining)
      }
    }, 1000)

    return () => clearInterval(interval)
  }, [expiresAt, onCodeExpired])

  const minutes = Math.floor(secondsLeft / 60)
  const seconds = secondsLeft % 60
  const countdown = `${minutes}:${seconds.toString().padStart(2, "0")}`

  return (
    <div className="flex flex-col items-center justify-center h-dvh bg-black text-white gap-6">
      <h1 className="text-2xl font-semibold text-white/40">Pair this screen</h1>

      <div className="text-7xl font-mono font-bold tracking-[0.25em] text-white">
        {code}
      </div>

      <p className="text-sm text-white/30">
        Enter this code in the RePlay app to connect this screen.
      </p>

      <p className="text-sm text-white/20 tabular-nums">
        Expires in {countdown}
      </p>
    </div>
  )
}
