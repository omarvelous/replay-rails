import type { Meta, StoryObj } from "@storybook/react-vite"
import { SplitLandscape } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

const meta = {
  title: "Ads/Split/Landscape",
  component: SplitLandscape,
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
} satisfies Meta<typeof SplitLandscape>

export default meta
type Story = StoryObj<typeof meta>

const baseAd = mockPlaylistAd({
  layout: "split",
  images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1920&h=1080&fit=crop" })],
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

export const NoAgent: Story = {
  args: { ad: baseAd, listingAd: mockListingAd({ agent: undefined }) },
}

export const NoImage: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "split", images: [] }),
    listingAd: baseAd.adable as ManifestListingAd,
  },
}
