import type { Meta, StoryObj } from "@storybook/react-vite"
import { OverlayLandscape } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

const meta = {
  title: "Ads/Overlay/Landscape",
  component: OverlayLandscape,
  decorators: [
    (Story, { globals }) => (
      <div style={{ width: 960, height: 540 }}>
        <AdCanvas theme={globals.adTheme ?? "dark"} aspect="landscape">
          <Story />
        </AdCanvas>
      </div>
    ),
  ],
  parameters: { layout: "centered", backgrounds: { default: "dark" } },
} satisfies Meta<typeof OverlayLandscape>

export default meta
type Story = StoryObj<typeof meta>

const baseAd = mockPlaylistAd({
  layout: "overlay",
  images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" })],
})

export const Default: Story = {
  args: { ad: baseAd, listingAd: baseAd.adable as ManifestListingAd },
}

export const PriceReduction: Story = {
  args: {
    ad: baseAd,
    listingAd: mockListingAd({
      badge: "price_reduction", badge_label: "Price Reduced",
      original_price: 2800000,
      listing: mockListing({ price: 2500000 }),
    }),
  },
}

export const JustSold: Story = {
  args: {
    ad: baseAd,
    listingAd: mockListingAd({
      badge: "just_sold", badge_label: "Just Sold",
      sold_price: 2600000,
    }),
  },
}

export const NoAgent: Story = {
  args: { ad: baseAd, listingAd: mockListingAd({ agent: undefined }) },
}

export const NoImage: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "overlay", images: [] }),
    listingAd: baseAd.adable as ManifestListingAd,
  },
}
