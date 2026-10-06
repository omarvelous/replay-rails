import type { Meta, StoryObj } from "@storybook/react-vite"
import { OverlayPortrait } from "."
import { AdCanvas } from "../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockAttachment } from "../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../types"

function Wrap(props: React.ComponentProps<typeof OverlayPortrait> & { theme?: string }) {
  return (
    <div style={{ width: 540, height: 960 }}>
      <AdCanvas theme={props.theme ?? "dark"} aspect="portrait">
        <OverlayPortrait {...props} />
      </AdCanvas>
    </div>
  )
}

const meta = {
  title: "Ads/Overlay/Portrait",
  component: OverlayPortrait,
  render: (args) => <Wrap {...args} />,
  parameters: { layout: "centered", backgrounds: { default: "dark" } },
} satisfies Meta<typeof OverlayPortrait>

export default meta
type Story = StoryObj<typeof meta>

const ad = mockPlaylistAd({
  layout: "overlay",
  images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" })],
})

export const Default: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd },
}

export const NoAgent: Story = {
  args: { ad, listingAd: mockListingAd({ agent: undefined }) },
}

export const NoImage: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "overlay", images: [] }),
    listingAd: ad.adable as ManifestListingAd,
  },
}
