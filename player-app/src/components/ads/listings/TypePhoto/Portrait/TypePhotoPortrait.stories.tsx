import type { Meta, StoryObj } from "@storybook/react-vite"
import { TypePhotoPortrait } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

const meta = {
  title: "Ads/TypePhoto/Portrait",
  component: TypePhotoPortrait,
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
} satisfies Meta<typeof TypePhotoPortrait>

export default meta
type Story = StoryObj<typeof meta>

const baseAd = mockPlaylistAd({
  layout: "type_photo",
  images: [
    mockAttachment({ url: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1920&h=1080&fit=crop" }),
  ],
})

export const Default: Story = {
  args: { ad: baseAd, listingAd: baseAd.adable as ManifestListingAd },
}

export const NoPhoto: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "type_photo", images: [] }),
    listingAd: mockListingAd({ badge: "coming_soon", badge_label: "Coming Soon" }),
  },
}
