import type { Meta, StoryObj } from "@storybook/react-vite"
import { Slideshow } from "."
import {
  mockManifestResponse,
  mockPlaylist,
  mockPlaylistAd,
  mockListingAd,
  mockAgentAd,
  mockBrandAd,
  mockAttachment,
  mockListing,
  mockAgent,
} from "../../../__mocks__/manifest"

const meta = {
  title: "Player/Slideshow",
  component: Slideshow,
  parameters: {
    layout: "fullscreen",
    backgrounds: { default: "dark" },
  },
} satisfies Meta<typeof Slideshow>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    manifest: mockManifestResponse(),
  },
}

export const JustListed: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Just Listed",
          body: "Stunning 3BR with panoramic city views.",
          images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" })],
          adable: mockListingAd({ badge: "just_listed", badge_label: "Just Listed" }),
        })],
      }),
    }),
  },
}

export const OpenHouse: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Open House",
          body: "Visit this Saturday 1-3 PM.",
          layout: "split",
          images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1920&h=1080&fit=crop" })],
          adable: mockListingAd({
            badge: "open_house",
            badge_label: "Open House",
            event_date: "Saturday, October 4",
            event_start_time: "1:00 PM",
            event_end_time: "3:00 PM",
          }),
        })],
      }),
    }),
  },
}

export const PriceReduction: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Price Reduced",
          body: "Now $300K below original asking.",
          images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1920&h=1080&fit=crop" })],
          adable: mockListingAd({
            badge: "price_reduction",
            badge_label: "Price Reduced",
            original_price: 4500000,
            listing: mockListing({ price: 4200000 }),
          }),
        })],
      }),
    }),
  },
}

export const AgentAd: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Jane Archer",
          body: "Your trusted real estate advisor.",
          layout: "profile",
          images: [mockAttachment({ url: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=1920&h=1080&fit=crop" })],
          adable: mockAgentAd(),
        })],
      }),
    }),
  },
}

export const BrandAd: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Your Window, Working 24/7",
          body: "Digital signage purpose-built for real estate.",
          layout: "hero",
          theme: "brand",
          images: [],
          adable: mockBrandAd(),
        })],
      }),
    }),
  },
}

export const NoImage: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "No Image Available",
          body: "This ad has no image attached.",
          images: [],
          adable: mockBrandAd(),
        })],
      }),
    }),
  },
}

export const SingleAd: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Solo Listing",
          duration: 30,
          images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" })],
        })],
      }),
    }),
  },
}

export const NoAgent: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockPlaylist({
        playlist_ads: [mockPlaylistAd({
          headline: "Listed Property",
          adable: mockListingAd({ agent: undefined }),
        })],
      }),
    }),
  },
}
