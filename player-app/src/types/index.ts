// API response wrapper
export interface ApiResponse<T> {
  data: T
}

export interface ApiError {
  error: { message: string }
}

// Registration
export interface RegistrationResponse {
  pairing_code: string
  token: string
  public_id: string
  expires_at: string
}

// Player status
export interface PlayerStatus {
  paired: boolean
}

// Heartbeat
export interface HeartbeatResponse {
  status: string
  content_version: number | null
}

// Manifest
export interface Manifest {
  content_type: "playlist" | "experience" | null
  screen: ManifestScreen
  playlist?: ManifestPlaylist
  experience?: ManifestExperience
}

export interface ManifestScreen {
  pid: string
  name: string
  orientation: string
}

export interface ManifestPlaylist {
  pid: string
  name: string
  ads: ManifestAd[]
}

export interface ManifestAd {
  pid: string
  headline: string
  body: string | null
  layout: string
  theme: string
  image_url: string | null
  position: number
  duration: number
}

export interface ManifestExperience {
  pid: string
  name: string
  listing: ManifestListing
  agent: ManifestAgent | null
  config: Record<string, unknown>
}

export interface ManifestListing {
  pid: string
  address: string
  price: number
  beds: number
  baths: number
  sqft: number
  photos: string[]
}

export interface ManifestAgent {
  pid: string
  name: string
  email: string
  phone: string | null
  photo_url: string | null
}
