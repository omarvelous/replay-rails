import type { Meta, StoryObj } from "@storybook/react-vite"
import { BandLandscape } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

const meta = {
  title: "Ads/Band/Landscape",
  component: BandLandscape,
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
} satisfies Meta<typeof BandLandscape>

export default meta
type Story = StoryObj<typeof meta>

const baseAd = mockPlaylistAd({
  layout: "band",
  images: [
    mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" }),
  ],
})

export const Default: Story = {
  args: { ad: baseAd, listingAd: baseAd.adable as ManifestListingAd },
}

export const NoAgent: Story = {
  args: { ad: baseAd, listingAd: mockListingAd({ agent: undefined }) },
}

export const NoImage: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "band", images: [] }),
    listingAd: baseAd.adable as ManifestListingAd,
  },
}
