import type { Meta, StoryObj } from "@storybook/react-vite"
import { Experience } from "."
import {
  mockManifestResponse,
  mockExperience,
  mockListingExperience,
  mockListing,
  mockAgent,
  mockAttachment,
} from "../../../__mocks__/manifest"

const meta = {
  title: "Player/Experience",
  component: Experience,
  parameters: {
    layout: "fullscreen",
    backgrounds: { default: "dark" },
  },
} satisfies Meta<typeof Experience>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockExperience(),
    }),
  },
}

export const WithPhoto: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockExperience({
        experienceable: mockListingExperience({
          listing: mockListing({
            photos: [
              mockAttachment({
                url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop",
              }),
            ],
          }),
        }),
      }),
    }),
  },
}

export const WithoutAgent: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockExperience({
        experienceable: mockListingExperience({ agent: undefined }),
      }),
    }),
  },
}

export const Rental: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockExperience({
        experienceable: mockListingExperience({
          listing: mockListing({
            price: 6750,
            beds: 1,
            baths: 1,
            sqft: 850,
            listing_type: "for_rent",
            address: "15 Hudson Yards, New York, NY 10001",
            photos: [
              mockAttachment({
                url: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1920&h=1080&fit=crop",
              }),
            ],
          }),
        }),
      }),
    }),
  },
}

export const NoPhotos: Story = {
  args: {
    manifest: mockManifestResponse({
      contentable: mockExperience({
        experienceable: mockListingExperience({
          listing: mockListing({ photos: [] }),
        }),
      }),
    }),
  },
}
