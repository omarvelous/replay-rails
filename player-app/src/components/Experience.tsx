import type { ManifestResponse } from "../queries/useManifestQuery"

interface ExperienceProps {
  manifest: ManifestResponse
}

export function Experience({ manifest }: ExperienceProps) {
  const contentable = manifest.contentable

  return (
    <div className="h-dvh w-full bg-black text-white overflow-hidden flex flex-col items-center justify-center">
      <p className="text-2xl font-semibold text-white/40">Experience</p>
      <p className="text-sm text-white/20 mt-2">{contentable?.pid}</p>
    </div>
  )
}
