import type { Meta, StoryObj } from "@storybook/react-vite"
import { StatGridPortrait } from "."
import { AdCanvas } from "../../../AdCanvas"
import { mockPlaylistAd, mockAttachment } from "../../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../../types"

const meta = {
  title: "Ads/StatGrid/Portrait",
  component: StatGridPortrait,
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
} satisfies Meta<typeof StatGridPortrait>

export default meta
type Story = StoryObj<typeof meta>

const baseAd = mockPlaylistAd({
  layout: "stat_grid",
  images: [
    mockAttachment({ url: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1920&h=1080&fit=crop" }),
  ],
})

export const Default: Story = {
  args: { ad: baseAd, listingAd: baseAd.adable as ManifestListingAd },
}
