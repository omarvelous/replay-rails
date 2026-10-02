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

// Ad type variants
export type ManifestAdable =
  | ManifestListingAd
  | ManifestAgentAd
  | ManifestBrandAd
  | ManifestCollectionAd

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

export interface ManifestAgentAd {
  type: "Ads::AgentAd"
  pid: string
  updated_at: number
  agent: ManifestAgent
}

export interface ManifestBrandAd {
  type: "Ads::BrandAd"
  pid: string
  updated_at: number
}

export interface ManifestCollectionAd {
  type: "Ads::CollectionAd"
  pid: string
  updated_at: number
  collection_ads: ManifestPlaylistAd[]
}

// Shared
export interface ManifestListing {
  pid: string
  updated_at: number
  address: string
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
