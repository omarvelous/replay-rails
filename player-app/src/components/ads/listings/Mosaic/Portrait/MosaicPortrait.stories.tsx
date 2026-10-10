import type { Meta, StoryObj } from "@storybook/react-vite"
import { MosaicPortrait } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../../__mocks__/manifest"

const meta = {
  title: "Ads/Mosaic/Portrait",
  component: MosaicPortrait,
  decorators: [
    (Story, { globals }) => (
      <div style={{ width: 540, height: 960 }}>
        <AdCanvas theme={globals.adTheme ?? "dark"} aspect="portrait">
          <Story />
        </AdCanvas>
      </div>
    ),
  ],
  parameters: { layout: "centered", backgrounds: { default: "dark" } },
} satisfies Meta<typeof MosaicPortrait>

export default meta
type Story = StoryObj<typeof meta>

const threePhotos = mockListing({
  photos: [
    mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" }),
    mockAttachment({ url: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800&h=600&fit=crop" }),
    mockAttachment({ url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800&h=600&fit=crop" }),
  ],
})

const baseAd = mockPlaylistAd({ layout: "mosaic" })

export const Default: Story = {
  args: { ad: baseAd, listingAd: mockListingAd({ listing: threePhotos }) },
}
