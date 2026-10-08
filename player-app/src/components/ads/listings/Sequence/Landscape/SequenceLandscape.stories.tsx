import type { Meta, StoryObj } from "@storybook/react-vite"
import { SequenceLandscape } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

const meta = {
  title: "Ads/Sequence/Landscape",
  component: SequenceLandscape,
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
} satisfies Meta<typeof SequenceLandscape>

export default meta
type Story = StoryObj<typeof meta>

const threePhotos = mockListing({
  photos: [
    mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" }),
    mockAttachment({ url: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1920&h=1080&fit=crop" }),
    mockAttachment({ url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1920&h=1080&fit=crop" }),
  ],
})

const baseAd = mockPlaylistAd({ layout: "sequence" })

export const Default: Story = {
  args: { ad: baseAd, listingAd: mockListingAd({ listing: threePhotos }) },
}

export const NoAgent: Story = {
  args: { ad: baseAd, listingAd: mockListingAd({ listing: threePhotos, agent: undefined }) },
}
