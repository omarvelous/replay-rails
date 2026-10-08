import type {
  ManifestResponse,
  ManifestPlaylist,
  ManifestPlaylistAd,
  ManifestListingAd,
  ManifestListing,
  ManifestAgent,
  ManifestAttachment,
  ManifestExperience,
  ManifestListingExperience,
} from "../types"

export function mockAttachment(overrides?: Partial<ManifestAttachment>): ManifestAttachment {
  return {
    id: 1,
    url: "/test/image.jpg",
    created_at: 1700000000,
    ...overrides,
  }
}

export function mockAgent(overrides?: Partial<ManifestAgent>): ManifestAgent {
  return {
    pid: "agent-001",
    updated_at: 1700000000,
    name: "Jane Archer",
    email: "jane@remax.com",
    phone: "+12125550012",
    bio: "Top-producing broker in Manhattan.",
    photos: [mockAttachment({ id: 10, url: "/test/agent.jpg" })],
    ...overrides,
  }
}

export function mockListing(overrides?: Partial<ManifestListing>): ManifestListing {
  return {
    pid: "listing-001",
    updated_at: 1700000000,
    address: "350 Fifth Ave, New York, NY 10118",
    street: "350 Fifth Ave",
    city: "New York",
    state: "NY",
    zip: "10118",
    neighborhood: "Midtown Manhattan",
    price: 2500000,
    beds: 3,
    baths: 2,
    sqft: 2200,
    property_type: "condo",
    listing_type: "for_sale",
    status: "active",
    photos: [mockAttachment({ id: 20, url: "/test/listing.jpg" })],
    floor_plans: [],
    ...overrides,
  }
}

export function mockListingAd(overrides?: Partial<ManifestListingAd>): ManifestListingAd {
  return {
    type: "Ads::ListingAd",
    pid: "listing-ad-001",
    updated_at: 1700000000,
    badge: "just_listed",
    badge_label: "Just Listed",
    event_date: null,
    event_start_time: null,
    event_end_time: null,
    original_price: null,
    sold_price: null,
    listing: mockListing(),
    agent: mockAgent(),
    ...overrides,
  }
}

export function mockPlaylistAd(overrides?: Partial<ManifestPlaylistAd>): ManifestPlaylistAd {
  return {
    pid: "playlist-ad-001",
    updated_at: 1700000000,
    position: 1,
    duration: 15,
    headline: "Just Listed",
    body: "Stunning 3BR with panoramic city views.",
    layout: "overlay",
    theme: "dark",
    images: [mockAttachment({ id: 30, url: "/test/ad-image.jpg" })],
    adable: mockListingAd(),
    ...overrides,
  }
}

export function mockPlaylist(overrides?: Partial<ManifestPlaylist>): ManifestPlaylist {
  return {
    type: "Playlist",
    pid: "playlist-001",
    updated_at: 1700000000,
    status: "published",
    playlist_ads: [
      mockPlaylistAd({ pid: "pa-1", position: 1, headline: "Just Listed" }),
      mockPlaylistAd({ pid: "pa-2", position: 2, headline: "Open House", layout: "split", adable: mockListingAd({ badge: "open_house", badge_label: "Open House" }) }),
      mockPlaylistAd({ pid: "pa-3", position: 3, headline: "Price Reduced", layout: "band", adable: mockListingAd({ badge: "price_reduction", badge_label: "Price Reduced" }) }),
    ],
    ...overrides,
  }
}

export function mockListingExperience(overrides?: Partial<ManifestListingExperience>): ManifestListingExperience {
  return {
    type: "Experiences::ListingExperience",
    pid: "listing-exp-001",
    updated_at: 1700000000,
    listing: mockListing(),
    agent: mockAgent(),
    ...overrides,
  }
}

export function mockExperience(overrides?: Partial<ManifestExperience>): ManifestExperience {
  return {
    type: "Experience",
    pid: "experience-001",
    updated_at: 1700000000,
    config: {},
    experienceable: mockListingExperience(),
    ...overrides,
  }
}

export function mockManifestResponse(overrides?: Partial<ManifestResponse>): ManifestResponse {
  return {
    deploy: "dev",
    screen_content: { pid: "sc-001", updated_at: 1700000000 },
    contentable: mockPlaylist(),
    ...overrides,
  }
}
