// API response wrapper
export interface ApiResponse<T> {
  data: T
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

// Manifest — matches the actual Jbuilder response
export interface ManifestResponse {
  deploy: string
  account_pid: string | null
  screen_pid: string | null
  screen_content: { pid: string; updated_at: number } | null
  contentable: ManifestPlaylist | ManifestExperience | null
}

// Playlist contentable
export interface ManifestPlaylist {
  type: "Playlist"
  pid: string
  updated_at: number
  status: string
  playlist_ads: ManifestPlaylistAd[]
}

// Experience contentable
export interface ManifestExperience {
  type: "Experience"
  pid: string
  updated_at: number
  config: Record<string, unknown>
  experienceable: ManifestListingExperience
}

export interface ManifestListingExperience {
  type: string
  pid: string
  updated_at: number
  listing: ManifestListing
  agent?: ManifestAgent
}

// Playlist ad — merged from _playlist_ad + _ad partials
export interface ManifestPlaylistAd {
  pid: string
  updated_at: number
  position: number
  duration: number
  headline: string
  body: string | null
  layout: string
  theme: string
  images: ManifestAttachment[]
  adable: ManifestAdable
}

// Ad type variant — only ListingAd
export type ManifestAdable = ManifestListingAd

export interface ManifestListingAd {
  type: "Ads::ListingAd"
  pid: string
  updated_at: number
  badge: string
  badge_label: string
  event_date: string | null
  event_start_time: string | null
  event_end_time: string | null
  original_price: number | null
  sold_price: number | null
  listing: ManifestListing
  agent?: ManifestAgent
}

// Shared
export interface ManifestListing {
  pid: string
  updated_at: number
  address: string
  street: string | null
  city: string | null
  state: string | null
  zip: string | null
  neighborhood: string | null
  price: number
  beds: number | null
  baths: number | null
  sqft: number | null
  property_type: string
  listing_type: string
  status: string
  photos: ManifestAttachment[]
  floor_plans: ManifestAttachment[]
}

export interface ManifestAgent {
  pid: string
  updated_at: number
  name: string
  email: string
  phone: string | null
  bio: string | null
  photos: ManifestAttachment[]
}

export interface ManifestAttachment {
  id: number
  url: string
  created_at: number
}
